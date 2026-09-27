#!/usr/bin/env python3
"""Run one Gemini use case for real and read what came back (`make gemini`).

The services under `backend/services/gemini/` are plain functions, so they can
always be called directly - in practice that meant writing a throwaway script
each time, inside the backend image, with the right imports. This is that
script, written once.

It prints **both** halves of the answer:

* the **raw text** Gemini produced, captured before any parser touches it, and
* the **parsed result**, the typed object the rest of the app would receive.

That pairing is the whole point. When a prompt drifts and the model answers in
a shape the schema rejects, the parse error alone says nothing useful; next to
the raw text it says everything. The raw text is printed even when the parse
blows up, and a use case that calls Gemini more than once (the resource search
searches, then describes what it found) prints every call.

**It spends real quota.** Every run is a billed call on the project's key, and
the output says so. Nothing in the test suite may call `run()`.

Usage::

    python -m backend.tools.gemini_cli                      # list the use cases
    python -m backend.tools.gemini_cli <use-case> [arg ...]
    make gemini ARGS='tutor-reply "Chess" "Learn chess openings" "How do I start?"'
    make gemini ARGS='--capture tutor-reply'   # the sample, saved for the tests

`--capture` also writes every response the run received, as the API sent it,
to `backend/tests/fixtures/responses/gemini/<use-case>.json` - the recording the
default suite replays through that use case's parse path (#207). With no
arguments it runs the use case's sample, which is what the replay is built with.
"""

import asyncio
import json
import sys
import traceback
import uuid
from collections.abc import Callable, Coroutine, Sequence
from dataclasses import dataclass, field, fields, is_dataclass
from pathlib import Path
from typing import Any

from pydantic import BaseModel

from backend.core import clock
from backend.core.config import settings
from backend.core.language import Language
from backend.schemas.goal import ObjectiveAnswer
from backend.services.gemini.chat.chat import gemini_messages_generator
from backend.services.gemini.chat.schema import GeminiChatMessage, StudentContextToChat
from backend.services.gemini.client import gemini_configs
from backend.services.gemini.lesson.lesson_generation import generate_lesson_questions
from backend.services.gemini.onboarding.goal_validation import get_prompt_validation
from backend.services.gemini.onboarding.onboarding import generate_onboarding_questions
from backend.services.gemini.onboarding.study_plan import generate_study_plan
from backend.services.gemini.placement import generate_placement_questions
from backend.services.gemini.resources.search_resources import search_resources
from backend.services.gemini.student_context.schema import GeminiStudentContext, StudentGoal
from backend.services.gemini.student_context.student_context import (
    gemini_generate_student_context,
    gemini_review_student_context,
)

# A goal id is only a foreign key here: the video search takes one to stamp on
# the Resource rows it builds, and nothing that uses this stores them.
UNSAVED_GOAL_ID = uuid.UUID(int=0)

# Every prompt names the student's language (#173); the command writes to an
# English-speaking student. Edit this to see another language's output.
CLI_LANGUAGE = Language.ENGLISH

# Where `--capture` writes a run's responses: the recordings the default suite
# replays (backend/tests/fixtures/captured.py `recorded`).
CAPTURES = Path(__file__).resolve().parents[1] / "tests" / "fixtures" / "responses" / "gemini"


@dataclass(frozen=True)
class UseCase:
    """One entry in the menu: how to call it, and what it costs to call.

    `sample` is a set of command-line arguments that works. It is printed as
    the example in the menu, and it is what the gate calls `build` with: see
    `backend/tests/test_tools/test_gemini_cli.py`, which type-checks the
    arguments this entry builds against the signature of the function it
    calls. Without it nothing catches a use case whose inputs changed (#120) -
    the arity usually still matches, so only the types give it away.

    `model_setting` names the settings field that holds the model, not the
    model itself: the table is built at import, and a name read here would be a
    copy a patched or overridden setting never reaches (#215).
    """

    name: str
    model_setting: str
    usage: str
    least_args: int
    build: Callable[[list[str]], tuple[Any, ...]]
    call: Callable[..., Coroutine[object, object, object]]
    sample: tuple[str, ...]
    note: str = ""

    @property
    def model(self) -> str:
        return str(getattr(settings, self.model_setting))


def _answers(pairs: list[str]) -> list[ObjectiveAnswer]:
    """`question=answer` on the command line, the schema the endpoint passes on."""
    out = []
    for pair in pairs:
        question, _, answer = pair.partition("=")
        out.append(ObjectiveAnswer(question=question, answer=answer))
    return out


def _turn(message: str) -> list[GeminiChatMessage]:
    return [GeminiChatMessage(role="user", message=message, time=clock.now().isoformat())]


def _goal(name: str, description: str, frontier: str = "") -> list[StudentGoal]:
    """One goal, as the context generators read a student's goals (#116). They
    take the list because a context is written about the person, not the goal;
    from the command line one is enough to see the prompt work.

    `frontier` is where the app is taking him now (#133). Empty means the
    prompt shows the description as the frontier, which is where a goal starts.
    """
    return [StudentGoal(name=name, description=description, frontier=frontier)]


def _context(state: str, metacognition: str) -> list[GeminiStudentContext]:
    """One standing reading of the student, as the prompts that consume a
    context read them (#116): a list, newest first."""
    return [GeminiStudentContext(state=state, metacognition=metacognition)]


USE_CASES: list[UseCase] = [
    UseCase(
        "goal-validation",
        "GEMINI_PREMIUM_MODEL",
        "<prompt>",
        1,
        lambda a: (a[0], CLI_LANGUAGE),
        get_prompt_validation,
        sample=("Learn chess openings",),
    ),
    UseCase(
        "objective-questions",
        "GEMINI_PREMIUM_MODEL",
        "<goal-name> <goal-description>",
        2,
        lambda a: (a[0], a[1], CLI_LANGUAGE),
        generate_onboarding_questions,
        sample=("Chess", "Learn chess openings"),
    ),
    UseCase(
        "study-plan",
        "GEMINI_PREMIUM_MODEL",
        "<prompt> [question=answer ...]",
        1,
        lambda a: (a[0], _answers(a[1:]), CLI_LANGUAGE),
        generate_study_plan,
        sample=("Learn chess", "How often?=Daily"),
    ),
    UseCase(
        "tutor-reply",
        "GEMINI_FAST_MODEL",
        "<goal-name> <goal-description> <student-message>",
        3,
        lambda a: (_turn(a[2]), [StudentContextToChat()], a[0], a[1], CLI_LANGUAGE),
        gemini_messages_generator,
        sample=("Chess", "Learn chess openings", "Where do I start?"),
        note="one turn, no history and an empty student context",
    ),
    UseCase(
        "lesson-questions",
        "GEMINI_FAST_MODEL",
        "<goal-name> <goal-description> <frontier> <state> <metacognition>",
        5,
        lambda a: (a[0], a[1], a[2], _context(a[3], a[4]), [], [], CLI_LANGUAGE),
        generate_lesson_questions,
        sample=(
            "Chess",
            "Learn chess openings",
            "Rook and pawn endgames",
            "Knows the moves",
            "Impatient",
        ),
        note="the exercises aim at the frontier, not the description (#133); nothing "
        "answered yet, so the prompt shows no exercises of his own",
    ),
    UseCase(
        "placement",
        "GEMINI_FAST_MODEL",
        "<goal-name> <what-he-typed> <state> <metacognition>",
        4,
        lambda a: (a[0], a[1], _context(a[2], a[3]), CLI_LANGUAGE),
        generate_placement_questions,
        sample=("Modern China", "i wanna understand modern day china", "New to it", "Curious"),
        note="a new goal's first PLACEMENT_SIZE exercises, from the most basic up",
    ),
    UseCase(
        "student-context",
        "GEMINI_PREMIUM_MODEL",
        "<goal-name> <goal-description> [onboarding-prompt]",
        2,
        lambda a: (_goal(a[0], a[1]), a[2] if len(a) > 2 else None, None, CLI_LANGUAGE),
        gemini_generate_student_context,
        sample=("Chess", "Learn chess openings", "I keep losing to my brother"),
        note="the first reading of a student: one goal, no onboarding answers",
    ),
    UseCase(
        "context-review",
        "GEMINI_PREMIUM_MODEL",
        "<goal-name> <goal-description> <state> <metacognition> [frontier]",
        4,
        lambda a: (
            _goal(a[0], a[1], a[4] if len(a) > 4 else ""),
            _context(a[2], a[3]),
            [],
            [],
            None,
            CLI_LANGUAGE,
        ),
        gemini_review_student_context,
        sample=("Chess", "Learn chess openings", "Knows the moves", "Impatient"),
        note="what went stale, what to add (#90) and whether the frontier has "
        "moved (#133); no answers or chats, so an empty answer is the right one",
    ),
    UseCase(
        "resource-search",
        "GEMINI_FAST_MODEL",
        "<goal-name> <goal-description> [student-context] [language: en|pt|es|fr|de]",
        2,
        lambda a: (
            a[0],
            a[1],
            a[2] if len(a) > 2 else None,
            [],
            Language(a[3]) if len(a) > 3 else CLI_LANGUAGE,
        ),
        search_resources,
        sample=("Chess", "Learn chess openings"),
        note="a grounded search, then a description of its sources (two calls). "
        "The pages' links are Google's redirects, unresolved; the videos are "
        "not searched (that is YouTube's API). Nothing is stored.",
    ),
]


@dataclass
class Recorder:
    """Captures every `generate_content` response's raw text.

    Every use case reaches Gemini through the client `gemini_configs.get_client`
    builds, which resolves `Client` from its own module at call time - so
    replacing that one name wraps every use case at once, and none of them has
    to know. Installed before the first call, so no client predates it.
    """

    raw: list[str] = field(default_factory=list)
    responses: list[BaseModel] = field(default_factory=list)

    def install(self) -> None:
        real_client = gemini_configs.Client

        # Passes every argument through untouched, so it is typed as loosely as
        # what it wraps is called; replacing a method and a class is what this
        # recorder is.
        def factory(*args: Any, **kwargs: Any) -> Any:
            client = real_client(*args, **kwargs)
            generate = client.aio.models.generate_content

            async def recording(*call_args: Any, **call_kwargs: Any) -> Any:
                response = await generate(*call_args, **call_kwargs)
                self.raw.append(response.text or "")
                self.responses.append(response)
                return response

            client.aio.models.generate_content = recording  # type: ignore[method-assign]
            return client

        gemini_configs.Client = factory  # type: ignore[misc, assignment]


def _cell(value: object) -> object:
    """Keep a 3072-float embedding from drowning the output it belongs to."""
    shape = getattr(value, "shape", None)
    if shape is not None:
        return f"<embedding {tuple(shape)}>"
    return value


def render(value: object) -> str:
    """The parsed result as text: Pydantic models as JSON, ORM rows as their
    columns, a dataclass field by field, anything else as its repr."""
    if is_dataclass(value) and not isinstance(value, type):
        return "\n".join(f"{f.name}:\n{render(getattr(value, f.name))}" for f in fields(value))
    if isinstance(value, BaseModel):
        return value.model_dump_json(indent=2)
    if isinstance(value, list):
        if not value:
            return "[] (nothing came back)"
        return "\n".join(f"[{i}]\n{render(item)}" for i, item in enumerate(value))
    table = getattr(type(value), "__table__", None)
    if table is not None:
        columns = {c.name: _cell(getattr(value, c.name, None)) for c in table.columns}
        return json.dumps(columns, indent=2, default=str)
    return repr(value)


def menu() -> str:
    lines = [
        "Run one Gemini use case for real and print the raw and parsed results.",
        "",
        "  python -m backend.tools.gemini_cli <use-case> [arg ...]",
        '  make gemini ARGS=\'<use-case> "arg" "arg"\'',
        "  make gemini ARGS='--capture <use-case>'   # also save the responses for the tests",
        "",
        "!! Every run SPENDS REAL QUOTA on this project's Gemini key. !!",
        "",
        "Use cases:",
    ]
    for case in USE_CASES:
        lines.append(f"  {case.name:<21} {case.usage}")
        lines.append(f"  {'':<21} model: {case.model}")
        lines.append(f"  {'':<21} e.g.: {' '.join(repr(arg) for arg in case.sample)}")
        if case.note:
            lines.append(f"  {'':<21} note: {case.note}")
    return "\n".join(lines)


def save(responses: Sequence[BaseModel], path: Path) -> None:
    """A run's responses as the replay reads them: a JSON list, one per call."""
    calls = [response.model_dump(mode="json", exclude_none=True) for response in responses]
    path.write_text(json.dumps(calls, ensure_ascii=False, indent=1) + "\n")


def run(case: UseCase, args: list[str], capture: bool = False) -> int:
    """Call one use case for real. Never called from the test suite."""
    recorder = Recorder()
    recorder.install()

    print(f"use case : {case.name}")
    print(f"model    : {case.model}")
    print(f"arguments: {args}")
    print("!! This is a REAL Gemini call and it spends real quota. !!\n")

    failure = None
    try:
        result = asyncio.run(case.call(*case.build(args)))
    except Exception as error:
        result, failure = None, error

    for index, raw in enumerate(recorder.raw, start=1):
        print(f"--- raw text from Gemini ({index}/{len(recorder.raw)}) ---")
        print(raw or "(empty)")
        print()
    if not recorder.raw:
        print("--- raw text from Gemini ---\n(no response arrived)\n")

    print("--- parsed result ---")
    if failure is not None:
        traceback.print_exception(type(failure), failure, failure.__traceback__)
        print("\nThe call above failed. The raw text is printed in full above it.")
        return 1
    print(render(result))
    if capture:
        save(recorder.responses, CAPTURES / f"{case.name}.json")
        print(f"\n{len(recorder.responses)} response(s) saved to {CAPTURES / case.name}.json")
    return 0


def main(argv: list[str]) -> int:
    capture = argv[1:2] == ["--capture"]
    if len(argv) < 2 + capture or argv[1] in ("-h", "--help"):
        print(menu())
        return 0

    wanted, args = argv[1 + capture], argv[2 + capture :]
    case = next((c for c in USE_CASES if c.name == wanted), None)
    if case is None:
        print(f"Unknown use case {wanted!r}.\n", file=sys.stderr)
        print(menu(), file=sys.stderr)
        return 2
    if capture and not args:
        args = list(case.sample)
    if len(args) < case.least_args:
        print(f"{case.name} needs: {case.usage}", file=sys.stderr)
        return 2
    return run(case, args, capture)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
