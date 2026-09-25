"""The rating is Rasch, and the answer is what moves it (#62).

This is arithmetic, so every claim here is a number: no database, no network,
no mock. What the tests pin is the shape of the curve, the schedule K decays
on, and the two movements the whole design exists for - a question far below
the student is worth almost nothing, one above him is worth a lot.
"""

import uuid
from datetime import UTC, datetime, timedelta

import pytest

from backend.models.question import Question
from backend.repositories.student_answer_repository import AnswerRecord
from backend.services.lessons.rasch import (
    START_RATING,
    difficulty,
    expected_score,
    k_factor,
    replay,
)

T0 = datetime(2026, 9, 1, tzinfo=UTC)


def question(minutes: int = 0) -> Question:
    """A bank question, in memory: the model reads its id and its birthday."""
    return Question(id=uuid.uuid4(), created_at=T0 + timedelta(minutes=minutes))


def answered(question: Question, outcomes: list[bool], first: int = 10) -> list[AnswerRecord]:
    """One answer a minute, `outcomes` in order."""
    return [
        AnswerRecord(question.id, T0 + timedelta(minutes=first + i), right)
        for i, right in enumerate(outcomes)
    ]


def test_the_guess_floor_prices_luck_out_of_every_right_answer():
    """Four options, so a quarter of a right answer is luck and E never goes under 0.25"""
    assert expected_score(1200, 1200) == 0.625  # not 0.5: the floor lifts the middle
    assert expected_score(1200, 800) == pytest.approx(0.9318, abs=1e-4)
    assert expected_score(1200, 1600) == pytest.approx(0.3182, abs=1e-4)
    assert expected_score(1200, 2400) == pytest.approx(0.2507, abs=1e-4)
    # A right answer on a question aimed at him pays K * 0.375, a quarter less
    # than a model without the floor would pay for the same answer.
    assert 1 - expected_score(1200, 1200) == 0.375


def test_k_decays_with_the_evidence():
    """Provisional while the goal is new, settled once it is not - and never zero"""
    assert k_factor(0) == 40.0
    assert k_factor(10) == 34.0
    assert k_factor(40) == 25.0
    assert k_factor(200) == 15.0
    assert k_factor(100_000) == pytest.approx(10.0, abs=0.02)
    assert k_factor(0) > k_factor(8) > k_factor(80) > k_factor(800)


def test_a_questions_difficulty_is_what_his_own_answers_say():
    """No tag, no column: `b` is the record, read back through the same curve"""
    assert difficulty(1200, 0, 0) == 1200  # never answered: worth what it was aimed at
    assert difficulty(1200, 1, 1) == pytest.approx(1079.59, abs=0.01)
    assert difficulty(1200, 4, 4) == pytest.approx(920.41, abs=0.01)
    assert difficulty(1200, 8, 8) == pytest.approx(818.30, abs=0.01)
    assert difficulty(1200, 2, 0) == pytest.approx(1616.56, abs=0.01)
    # Five of eight is exactly his level: at the level, E is 0.625, not a coin.
    assert difficulty(1200, 8, 5) == pytest.approx(1200.0, abs=0.01)
    assert difficulty(1200, 8, 4) > 1200  # half of them is already above him
    # A question cannot run away from its anchor, however long the run.
    assert difficulty(1200, 1000, 1000) == pytest.approx(1200 - 798.25, abs=0.01)


def test_a_right_answer_far_below_the_student_barely_moves_the_rating():
    """Four right answers put the question 280 points under him; the fifth is
    worth under four points"""
    easy = question()
    history = answered(easy, [True] * 4)

    before = replay([easy], history)
    after = replay([easy], history + answered(easy, [True], first=20))

    assert before.rating == 1236
    assert before.difficulty[easy.id] == pytest.approx(920.41, abs=0.01)
    assert after.rating - before.rating == 4


def test_a_right_answer_above_the_student_moves_it_clearly():
    """The same right answer, on a question he had missed twice: 27 points"""
    hard = question()
    history = answered(hard, [False, False])

    before = replay([hard], history)
    after = replay([hard], history + answered(hard, [True], first=20))

    assert before.rating == 1159
    assert before.difficulty[hard.id] == pytest.approx(1616.56, abs=0.01)
    assert after.rating - before.rating == 27


def test_an_unanswered_question_is_worth_the_rating_it_was_generated_at():
    """The walk is in time order, so a question born tonight is anchored at the
    rating of tonight - not at the one the student ends the month on"""
    old = question(minutes=0)
    fresh = question(minutes=60)
    history = answered(old, [True] * 4)

    ratings = replay([old, fresh], history)

    assert ratings.rating == 1236
    assert ratings.difficulty[fresh.id] == pytest.approx(1235.68, abs=0.01)
    assert replay([fresh], []).difficulty[fresh.id] == START_RATING


def test_the_same_history_always_replays_to_the_same_rating():
    """Nothing random is left in grading: the rating is a function of the answers"""
    bank = [question(i) for i in range(4)]
    history = [
        record
        for i, item in enumerate(bank)
        for record in answered(item, [True, False, True], first=10 + 3 * i)
    ]
    history.sort(key=lambda record: record.answered_at)

    first = replay(bank, history)
    second = replay(bank, history)

    assert first.rating == second.rating
    assert first.difficulty == second.difficulty
    assert first.answers_seen == 12
    assert first.rating != START_RATING
