"""The Gemini runner's menu and argument handling.

Every test here stays on the near side of the network: `run()` is replaced with
a fuse that fails the test if anything reaches it, because a test suite that
calls this command for real spends the project's money.
"""

import pytest

from backend.schemas.goal import ObjectiveAnswer
from backend.services.gemini.onboarding.schema import GeminiGoalValidation
from backend.tools import gemini_cli

# The use cases the command has to cover (issue #94).
EXPECTED = {
    "goal-validation",
    "objective-questions",
    "study-plan",
    "introduction",
    "tutor-reply",
    "lesson-questions",
    "student-context",
    "resource-search",
}


@pytest.fixture(autouse=True)
def never_calls_gemini(monkeypatch):
    def fuse(case, args):
        raise AssertionError(f"the test suite tried to spend real quota on {case.name}")

    monkeypatch.setattr(gemini_cli, "run", fuse)


def test_every_use_case_is_covered():
    assert {case.name for case in gemini_cli.USE_CASES} == EXPECTED


def test_no_arguments_lists_the_use_cases_and_says_it_costs(capsys):
    assert gemini_cli.main(["gemini_cli"]) == 0

    printed = capsys.readouterr().out
    assert all(name in printed for name in EXPECTED)
    assert "SPENDS REAL QUOTA" in printed


def test_an_unknown_use_case_is_refused():
    assert gemini_cli.main(["gemini_cli", "no-such-thing"]) == 2


def test_missing_arguments_are_refused_before_any_call(capsys):
    assert gemini_cli.main(["gemini_cli", "lesson-questions", "Chess"]) == 2
    assert "<metacognition>" in capsys.readouterr().err


def test_command_line_pairs_become_objective_answers():
    case = next(c for c in gemini_cli.USE_CASES if c.name == "study-plan")

    prompt, answers = case.build(["Learn chess", "How often?=Daily", "Level?=Beginner"])

    assert prompt == "Learn chess"
    assert answers == [
        ObjectiveAnswer(question="How often?", answer="Daily"),
        ObjectiveAnswer(question="Level?", answer="Beginner"),
    ]


def test_the_tutor_reply_is_built_as_one_user_turn():
    case = next(c for c in gemini_cli.USE_CASES if c.name == "tutor-reply")

    messages, contexts, goal_name, description = case.build(
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
