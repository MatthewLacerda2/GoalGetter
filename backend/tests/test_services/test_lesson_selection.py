"""Which eight questions a student gets, and why those (#134).

Arithmetic, so every claim here is a number: no database, no network, no mock.
What the tests pin is the shape of each term, the five claims the issue's
definition of done is made of, and the one thing a comment cannot prove - that
nothing in this path can reach Gemini.
"""

import ast
import uuid
from datetime import UTC, datetime, timedelta
from pathlib import Path

import numpy as np
import pytest

from backend.models.frontier import Frontier
from backend.models.question import Question
from backend.models.student_context import StudentContext
from backend.repositories.student_answer_repository import AnswerRecord
from backend.services.lessons.selection import (
    NEUTRAL,
    TOLERANCE_ABOVE,
    WEIGHT_CONTEXT,
    Recall,
    context_affinity,
    forgetting_score,
    rank_bank,
    select_lesson_questions,
    threshold_score,
)
from backend.utils.envs import NUM_DIMENSIONS

T0 = datetime(2026, 9, 1, tzinfo=UTC)
NOW = T0 + timedelta(days=10)


def vector(*axes) -> np.ndarray:
    """An embedding pointing along the given axes: two of them are the same
    direction, perpendicular, or somewhere between, with no arithmetic in the
    test itself."""
    built = np.zeros(NUM_DIMENSIONS, dtype=np.float32)
    for axis, value in axes:
        built[axis] = value
    return built


def question(name: str, born: int = 0, embedding=None) -> Question:
    """A bank question called `name`, born `born` minutes into the fixed clock."""
    return Question(
        id=uuid.uuid5(uuid.NAMESPACE_DNS, name),
        text=name,
        created_at=T0 + timedelta(minutes=born),
        text_embedding=embedding,
    )


def answered(item: Question, *days_ago_and_right) -> list[AnswerRecord]:
    """Answers to one question: `(days before NOW, was it right)` each."""
    return [
        AnswerRecord(item.id, NOW - timedelta(days=days), right)
        for days, right in days_ago_and_right
    ]


def lesson(bank, history=(), size=8, **kwargs) -> list[str]:
    ordered = sorted(history, key=lambda record: record.answered_at)
    return [q.text for q in select_lesson_questions(bank, ordered, size, now=NOW, **kwargs)]


def test_the_threshold_is_three_answers_in_four_and_falls_away_faster_on_the_easy_side():
    """0.75 is the product decision; the bell is narrower above it because the
    whole of "he already knows this" lives in the quarter above 0.75"""
    assert threshold_score(0.75) == 1.0
    assert threshold_score(0.625) == pytest.approx(0.7066, abs=1e-4)  # par, with the guess floor
    assert threshold_score(0.5) == pytest.approx(0.2494, abs=1e-4)
    assert threshold_score(0.25) == pytest.approx(0.0039, abs=1e-4)  # a pure coin: never serve it
    assert threshold_score(0.9) == pytest.approx(0.1353, abs=1e-4)
    assert threshold_score(1.0) == pytest.approx(0.0039, abs=1e-4)
    # The same 0.15 of E, either side of the target, is not the same distance.
    assert threshold_score(0.90) < threshold_score(0.60)
    assert TOLERANCE_ABOVE == 0.075


def test_the_horizon_grows_with_each_correct_answer_and_falls_back_on_a_wrong_one():
    """A question he settles fades out; one he misses is due again tomorrow"""
    due = [forgetting_score(Recall(NOW - timedelta(days=1), streak), NOW) for streak in range(5)]
    assert due == pytest.approx([0.6321, 0.3297, 0.1479, 0.0620, 0.0253], abs=1e-4)
    assert due[0] > 10 * due[3]  # wrong yesterday against settled three times over
    assert forgetting_score(Recall(), NOW) == 0.0  # never answered: nothing has decayed
    assert forgetting_score(Recall(NOW - timedelta(days=45)), NOW) == pytest.approx(1.0)


def test_the_same_history_at_the_same_hour_is_always_the_same_lesson():
    """Deterministic: no sampling, no shuffle, ties broken by created_at then id"""
    bank = [question(f"q{i}", born=i, embedding=vector((i, 1.0))) for i in range(12)]
    history = [
        record
        for i, item in enumerate(bank[:6])
        for record in answered(item, (3 + i, i % 2 == 0), (1 + i % 3, i % 3 == 0))
    ]

    served = {tuple(lesson(bank, history, size=8)) for _ in range(20)}

    assert len(served) == 1
    assert len(served.pop()) == 8


def test_a_question_settled_three_times_stays_out_and_one_missed_yesterday_comes_back():
    """The user's own example: three right in a row is learned, one wrong is not"""
    settled, missed = question("settled", born=0), question("missed", born=1)
    bank = [settled, missed] + [question(f"fresh{i}", born=2 + i) for i in range(4)]
    history = answered(settled, (4, True), (3, True), (2, True)) + answered(missed, (1, False))

    served = lesson(bank, history, size=5)

    assert "settled" not in served
    assert "missed" in served
    assert served == ["fresh0", "fresh1", "fresh2", "fresh3", "missed"]


def test_a_lesson_is_never_one_question_written_four_ways():
    """Coverage: near-identical embeddings, and only the first of them is served"""
    clones = [
        question(f"clone{i}", born=i, embedding=vector((0, 1.0), (50 + i, 0.02))) for i in range(4)
    ]
    others = [question(f"other{i}", born=10 + i, embedding=vector((5 + i, 1.0))) for i in range(4)]

    served = lesson(clones + others, size=4)

    assert served == ["clone0", "other0", "other1", "other2"]
    # Without the vectors there is nothing to compare, and the bank's own order
    # stands: a missing embedding never blocks a lesson, it only stops helping.
    blind = [question(name, born=i) for i, name in enumerate(["c0", "c1", "c2", "c3", "o0"])]
    assert lesson(blind, size=4) == ["c0", "c1", "c2", "c3"]


def test_the_lesson_aims_at_the_goals_frontier_and_not_at_its_description():
    """#133: the target is the frontier row, and it can outrank the older question"""
    far = question("elsewhere", born=0, embedding=vector((9, 1.0)))
    near = question("on target", born=1, embedding=vector((7, 1.0)))
    frontier = Frontier(definition="robotics", definition_embedding=vector((7, 1.0)))

    assert lesson([far, near], size=1, frontier=frontier) == ["on target"]
    assert lesson([far, near], size=1) == ["elsewhere"]  # no frontier: the older one leads


def test_the_student_context_term_is_wired_and_weighs_nothing():
    """#134: computed, provably zero, and turned on later with data in hand"""
    assert WEIGHT_CONTEXT == 0.0
    bank = [question(f"q{i}", born=i, embedding=vector((i, 1.0))) for i in range(4)]
    aligned = StudentContext(
        state_embedding=vector((0, 1.0)), metacognition_embedding=vector((0, 1.0))
    )
    opposed = StudentContext(
        state_embedding=vector((3, 1.0)), metacognition_embedding=vector((3, 1.0))
    )

    # The term really is computed - it is not a stub returning the same number.
    assert context_affinity(bank[0], aligned) == pytest.approx(1.0)
    assert context_affinity(bank[0], opposed) == pytest.approx(0.0)
    assert context_affinity(bank[0], None) == 0.5
    # And it changes no lesson, because nothing is measuring it yet.
    assert lesson(bank, size=2, context=aligned) == lesson(bank, size=2, context=opposed)


def test_cold_start_is_not_a_special_case_the_ranking_simply_falls_through():
    """No answers: E ties everywhere, so novelty and coverage serve what we have"""
    bank = [question(f"q{i}", born=9 - i) for i in range(6)]

    assert lesson(bank, size=4) == ["q5", "q4", "q3", "q2"]
    assert lesson(bank, size=99) == ["q5", "q4", "q3", "q2", "q1", "q0"]  # a cap, not a floor
    assert select_lesson_questions([], [], 8, now=NOW) == []


def test_the_whole_bank_is_scored_and_the_terms_are_readable_from_outside():
    """#135 reads this: a bank nobody can be served from is what buys a generation"""
    spent = [question(f"spent{i}", born=i) for i in range(3)]
    fresh = question("fresh", born=9)
    history = [
        record for item in spent for record in answered(item, (3, True), (2, True), (1, True))
    ]

    ranked = {
        entry.question.text: entry
        for entry in rank_bank(
            spent + [fresh], sorted(history, key=lambda r: r.answered_at), now=NOW
        )
    }

    assert len(ranked) == 4  # every question of the bank, not only the served ones
    assert ranked["fresh"].novelty == 1.0 and ranked["spent0"].novelty == 0.0
    assert ranked["spent0"].forgetting < 0.1  # settled: nothing has decayed yet
    assert ranked["fresh"].score(NEUTRAL) > max(
        ranked[f"spent{i}"].score(NEUTRAL) for i in range(3)
    )


def backend_imports(module: str) -> set:
    """Every `backend.*` module this one imports, read off its source."""
    path = Path(__file__).parents[3] / Path(*module.split("."))
    source = path.with_suffix(".py")
    tree = ast.parse((source if source.exists() else path / "__init__.py").read_text())
    found = {
        alias.name
        for node in ast.walk(tree)
        if isinstance(node, ast.Import)
        for alias in node.names
    }
    found |= {
        node.module for node in ast.walk(tree) if isinstance(node, ast.ImportFrom) and node.module
    }
    return found


def reachable(*roots: str) -> set:
    """The whole import closure of `roots`, project modules and third parties alike."""
    seen, queue = set(), list(roots)
    while queue:
        module = queue.pop()
        if module in seen:
            continue
        seen.add(module)
        queue.extend(backend_imports(module) if module.startswith("backend.") else [])
    return seen


def test_no_gemini_call_can_be_reached_from_the_selection_path():
    """#134's whole point: choosing questions is arithmetic, asserted not assumed"""
    closure = reachable(
        "backend.services.lessons.selection",
        "backend.services.lessons.pacing",
    )

    assert "backend.services.lessons.rasch" in closure  # the closure really was walked
    forbidden = [name for name in closure if "gemini" in name or "genai" in name]
    assert forbidden == []
    assert [name for name in closure if "youtube" in name] == []
