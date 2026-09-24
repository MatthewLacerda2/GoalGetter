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
searches, then reformats) prints every call.

**It spends real quota.** Every run is a billed call on the project's key, and
the output says so. Nothing in the test suite may call `run()`.

Usage::

    python -m backend.tools.gemini_cli                      # list the use cases
    python -m backend.tools.gemini_cli <use-case> [arg ...]
    make gemini ARGS='tutor-reply "Chess" "Learn chess openings" "How do I start?"'
"""

import json
import sys
import traceback
from collections.abc import Callable
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any

from pydantic import BaseModel

from backend.schemas.goal import ObjectiveAnswer
from backend.services.gemini.chat.chat import gemini_messages_generator
from backend.services.gemini.chat.schema import GeminiChatMessage, StudentContextToChat
from backend.services.gemini.lesson.lesson_generation import generate_lesson_questions
from backend.services.gemini.onboarding.goal_validation import get_prompt_validation
from backend.services.gemini.onboarding.introduction import generate_introduction_screens
from backend.services.gemini.onboarding.onboarding import generate_onboarding_questions
from backend.services.gemini.onboarding.study_plan import generate_study_plan
from backend.services.gemini.resources.search_resources import search_resources
from backend.services.gemini.student_context.student_context import (
    gemini_generate_student_context,
)
from backend.utils.envs import GEMINI_FAST_MODEL, GEMINI_PREMIUM_MODEL
from backend.utils.gemini import gemini_configs

# A goal id is only a foreign key here: the resource search takes one to stamp
# on the Resource rows it builds, and this command never stores them.
UNSAVED_GOAL_ID = "00000000-0000-0000-0000-000000000000"


@dataclass(frozen=True)
class UseCase:
    """One entry in the menu: how to call it, and what it costs to call."""

    name: str
    model: str
    usage: str
    least_args: int
    build: Callable[[list[str]], tuple]
    call: Callable[..., Any]
    note: str = ""


def _answers(pairs: list[str]) -> list[ObjectiveAnswer]:
    """`question=answer` on the command line, the schema the endpoint passes on."""
    out = []
    for pair in pairs:
        question, _, answer = pair.partition("=")
        out.append(ObjectiveAnswer(question=question, answer=answer))
    return out


def _turn(message: str) -> list[GeminiChatMessage]:
    return [GeminiChatMessage(role="user", message=message, time=datetime.now().isoformat())]


USE_CASES: list[UseCase] = [
    UseCase(
        "goal-validation",
        GEMINI_PREMIUM_MODEL,
        "<prompt>",
        1,
        lambda a: (a[0],),
        get_prompt_validation,
    ),
    UseCase(
        "objective-questions",
        GEMINI_PREMIUM_MODEL,
        "<goal-name> <goal-description>",
        2,
        lambda a: (a[0], a[1]),
        generate_onboarding_questions,
    ),
    UseCase(
        "study-plan",
        GEMINI_PREMIUM_MODEL,
        "<prompt> [question=answer ...]",
        1,
        lambda a: (a[0], _answers(a[1:])),
        generate_study_plan,
    ),
    UseCase(
        "introduction",
        GEMINI_PREMIUM_MODEL,
        "<goal-name> <goal-description>",
        2,
        lambda a: (a[0], a[1]),
        generate_introduction_screens,
    ),
    UseCase(
        "tutor-reply",
        GEMINI_FAST_MODEL,
        "<goal-name> <goal-description> <student-message>",
        3,
        lambda a: (_turn(a[2]), [StudentContextToChat()], a[0], a[1]),
        gemini_messages_generator,
        note="one turn, no history and an empty student context",
    ),
    UseCase(
        "lesson-questions",
        GEMINI_FAST_MODEL,
        "<goal-name> <goal-description> <rating> <state> <metacognition>",
        5,
        lambda a: (a[0], a[1], int(a[2]), a[3], a[4]),
        generate_lesson_questions,
    ),
    UseCase(
        "student-context",
        GEMINI_PREMIUM_MODEL,
        "<goal-name> <goal-description> [onboarding-prompt]",
        2,
        lambda a: (a[0], a[1], a[2] if len(a) > 2 else None),
        gemini_generate_student_context,
    ),
    UseCase(
        "resource-search",
        GEMINI_FAST_MODEL,
        "<goal-name> <goal-description> [student-context]",
        2,
        lambda a: (UNSAVED_GOAL_ID, a[0], a[1], a[2] if len(a) > 2 else None),
        search_resources,
        note="three billed calls: a grounded search, a reformat, then one embedding "
        "per resource. Nothing is stored.",
    ),
]


@dataclass
class Recorder:
    """Captures every `generate_content` response's raw text.

    The use cases each build their own client through `gemini_configs.get_client`,
    which resolves `Client` from its own module at call time - so replacing that
    one name wraps every use case at once, and none of them has to know.
    """

    raw: list[str] = field(default_factory=list)

    def install(self) -> None:
        real_client = gemini_configs.Client

        def factory(*args, **kwargs):
            client = real_client(*args, **kwargs)
            generate = client.models.generate_content

            def recording(*call_args, **call_kwargs):
                response = generate(*call_args, **call_kwargs)
                self.raw.append(response.text or "")
                return response

            client.models.generate_content = recording
            return client

        gemini_configs.Client = factory


def _cell(value: Any) -> Any:
    """Keep a 3072-float embedding from drowning the output it belongs to."""
    if hasattr(value, "shape"):
        return f"<embedding {tuple(value.shape)}>"
    return value


def render(value: Any) -> str:
    """The parsed result as text: Pydantic models as JSON, ORM rows as their
    columns, anything else as its repr."""
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
        "",
        "!! Every run SPENDS REAL QUOTA on this project's Gemini key. !!",
        "",
        "Use cases:",
    ]
    for case in USE_CASES:
        lines.append(f"  {case.name:<21} {case.usage}")
        lines.append(f"  {'':<21} model: {case.model}")
        if case.note:
            lines.append(f"  {'':<21} note: {case.note}")
    return "\n".join(lines)


def run(case: UseCase, args: list[str]) -> int:
    """Call one use case for real. Never called from the test suite."""
    recorder = Recorder()
    recorder.install()

    print(f"use case : {case.name}")
    print(f"model    : {case.model}")
    print(f"arguments: {args}")
    print("!! This is a REAL Gemini call and it spends real quota. !!\n")

    failure = None
    try:
        result = case.call(*case.build(args))
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
    return 0


def main(argv: list[str]) -> int:
    if len(argv) < 2 or argv[1] in ("-h", "--help"):
        print(menu())
        return 0

    wanted, args = argv[1], argv[2:]
    case = next((c for c in USE_CASES if c.name == wanted), None)
    if case is None:
        print(f"Unknown use case {wanted!r}.\n", file=sys.stderr)
        print(menu(), file=sys.stderr)
        return 2
    if len(args) < case.least_args:
        print(f"{case.name} needs: {case.usage}", file=sys.stderr)
        return 2
    return run(case, args)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
