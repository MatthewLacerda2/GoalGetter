"""The Gemini runner's menu and argument handling.

Every test here stays on the near side of the network: `run()` is replaced with
a fuse that fails the test if anything reaches it, because a test suite that
calls this command for real spends the project's money.
"""

import ast
import inspect

import pytest
from pydantic import TypeAdapter

from backend.schemas.goal import ObjectiveAnswer
from backend.services.gemini.client import gemini_call
from backend.services.gemini.onboarding.schema import GeminiGoalValidation
from backend.tests.fixtures.captured import recorded
from backend.tests.fixtures.code import modules_under
from backend.tools import gemini_cli

# The doors to Gemini a use case may call (#216). Anything that calls one of
# them is a use case, whatever it is named.
SHARED_CALLS = (gemini_call.generate, gemini_call.grounded_search)


def _callee(module, func: ast.expr):
    """The object a call expression names, looked up in the module it is in -
    so `generate(...)`, an alias of it, and `gemini_call.generate(...)` are one."""
    if isinstance(func, ast.Name):
        return vars(module).get(func.id)
    if isinstance(func, ast.Attribute) and isinstance(func.value, ast.Name):
        return getattr(vars(module).get(func.value.id), func.attr, None)
    return None


def gemini_use_cases() -> set:
    """Every function under `services/gemini/` that calls Gemini, read off the
    code (#212): a new use case is found the moment it makes its first call,
    with nobody having to list it anywhere."""
    found = set()
    for module in modules_under("services/gemini"):
        if module is gemini_call:
            continue
        for node in ast.parse(inspect.getsource(module)).body:
            if not isinstance(node, ast.FunctionDef | ast.AsyncFunctionDef):
                continue
            calls = [n for n in ast.walk(node) if isinstance(n, ast.Call)]
            if any(_callee(module, call.func) in SHARED_CALLS for call in calls):
                found.add(getattr(module, node.name))
    return found


@pytest.fixture(autouse=True)
def never_calls_gemini(monkeypatch):
    def fuse(case, args, capture=False):
        raise AssertionError(f"the test suite tried to spend real quota on {case.name}")

    monkeypatch.setattr(gemini_cli, "run", fuse)


def test_every_function_that_calls_gemini_is_a_use_case_of_the_command():
    """The command's list is what the live suite calls and what the prompt
    rules are checked against, so a use case missing from it escapes both."""
    listed = {case.call for case in gemini_cli.USE_CASES}

    assert len(listed) == len(gemini_cli.USE_CASES)
    assert gemini_use_cases() == listed


def test_no_arguments_lists_the_use_cases_and_says_it_costs(capsys):
    assert gemini_cli.main(["gemini_cli"]) == 0

    printed = capsys.readouterr().out
    assert all(case.name in printed for case in gemini_cli.USE_CASES)
    assert "SPENDS REAL QUOTA" in printed


def test_an_unknown_use_case_is_refused():
    assert gemini_cli.main(["gemini_cli", "no-such-thing"]) == 2


def test_missing_arguments_are_refused_before_any_call(capsys):
    assert gemini_cli.main(["gemini_cli", "lesson-questions", "Chess"]) == 2
    assert "<metacognition>" in capsys.readouterr().err


def test_capture_alone_runs_the_sample_and_asks_for_the_recording(monkeypatch):
    """The sample is what the replay test builds its call with (#207)"""
    asked = []
    monkeypatch.setattr(gemini_cli, "run", lambda *call: asked.append(call) or 0)

    assert gemini_cli.main(["gemini_cli", "--capture", "study-plan"]) == 0

    ((case, args, capture),) = asked
    assert (case.name, args, capture) == ("study-plan", list(case.sample), True)


def test_a_capture_is_saved_in_the_shape_the_replay_reads(tmp_path):
    calls = recorded("resource-search")

    gemini_cli.save(calls, tmp_path / "resource-search.json")

    assert recorded("resource-search", tmp_path) == calls


@pytest.mark.parametrize("case", gemini_cli.USE_CASES, ids=lambda case: case.name)
def test_the_arguments_an_entry_builds_are_the_ones_its_function_takes(case):
    """The gate #120 asked for: every door opens.

    Two entries had been broken for weeks because a use case's inputs changed
    under them (#116) and nothing exercised the call site - the command may
    never call Gemini from the suite, so the only thing left to check is the
    *shape* of what it would have sent. Arity alone would not have caught
    either one: both passed the right number of arguments, as strings, where
    the function wanted a list of models. So each argument is validated against
    its parameter's annotation, strictly, which is exactly the mismatch.

    The alternative weighed in the issue - having the build smoke import the
    registry - was not enough for the same reason: importing the module proves
    the names resolve, and both bugs were in code that imported perfectly well
    and only failed at the call.
    """
    arguments = case.build(list(case.sample))
    signature = inspect.signature(case.call)
    bound = signature.bind(*arguments)

    for name, value in bound.arguments.items():
        annotation = signature.parameters[name].annotation
        assert annotation is not inspect.Parameter.empty, f"{case.name}: {name} is unannotated"
        TypeAdapter(annotation).validate_python(value, strict=True)


def test_command_line_pairs_become_objective_answers():
    case = next(c for c in gemini_cli.USE_CASES if c.name == "study-plan")

    prompt, answers, _language = case.build(["Learn chess", "How often?=Daily", "Level?=Beginner"])

    assert prompt == "Learn chess"
    assert answers == [
        ObjectiveAnswer(question="How often?", answer="Daily"),
        ObjectiveAnswer(question="Level?", answer="Beginner"),
    ]


def test_the_tutor_reply_is_built_as_one_user_turn():
    case = next(c for c in gemini_cli.USE_CASES if c.name == "tutor-reply")

    messages, contexts, goal_name, description, _language = case.build(
        ["Chess", "Openings", "Where do I start?"]
    )

    assert [m.role for m in messages] == ["user"]
    assert messages[0].message == "Where do I start?"
    assert len(contexts) == 1
    assert (goal_name, description) == ("Chess", "Openings")


def test_a_parsed_result_renders_as_json():
    parsed = GeminiGoalValidation(
        is_harmless=True, is_achievable=True, makes_sense=True, reasoning="fine"
    )

    assert '"reasoning": "fine"' in gemini_cli.render(parsed)


def test_an_embedding_is_summarised_not_dumped():
    class Fake:
        shape = (3072,)

    assert gemini_cli._cell(Fake()) == "<embedding (3072,)>"
