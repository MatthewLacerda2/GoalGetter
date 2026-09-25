import uuid
from datetime import UTC, datetime, timedelta

import pytest

from backend.core import clock
from backend.models.question import Question
from backend.models.student_answer import StudentAnswer

# A fixed clock for the lesson tests: `at(n)` is n minutes after it.
T0 = datetime(2026, 9, 1, tzinfo=UTC)


def at(minutes: int) -> datetime:
    return T0 + timedelta(minutes=minutes)


@pytest.fixture
def question_factory(test_db):
    """A bank question for a goal. The right choice is `correct` (default 0).

    `options` names the four choices where a test cares what they say: the
    generation prompt carries the option the student picked (#135), so proving
    that needs four options a test can tell apart.
    """

    async def _create(goal, text="Q?", correct=0, created_at=None, options=("a", "b", "c", "d")):
        question = Question(
            goal_id=goal.id,
            text=text,
            option_a=options[0],
            option_b=options[1],
            option_c=options[2],
            option_d=options[3],
            right_answer_index=correct,
            created_at=created_at or T0,
        )
        test_db.add(question)
        await test_db.flush()
        return question

    return _create


@pytest.fixture
def answer_factory(test_db):
    """An answer to `question`, right or wrong, given at `answered_at`, under a
    lesson mark of its own."""

    async def _create(question, correct: bool, answered_at: datetime, lesson_id=None, position=0):
        answer = StudentAnswer(
            lesson_id=lesson_id or uuid.uuid4(),
            position=position,
            question_id=question.id,
            selected_index=question.right_answer_index
            if correct
            else (question.right_answer_index + 1) % 4,
            total_seconds=5,
            created_at=answered_at,
        )
        test_db.add(answer)
        await test_db.flush()
        return answer

    return _create


def days_ago(days: int, hour: int = 12) -> datetime:
    """An aware moment `days` days before today, at `hour` on the app's wall
    clock. Noon by default, far from midnight, so the app's date is never
    ambiguous."""
    return clock.app_moment(clock.today() - timedelta(days=days), hour)


@pytest.fixture
def lesson_factory(test_db, question_factory, answer_factory):
    """One lesson: `size` answers of `goal` sharing a minted `lesson_id`, given
    at `answered_at`, the first `correct` of them right.

    There is no lesson row to create (#131) - a lesson is exactly this batch -
    so what comes back is the mark the batch carries.
    """

    async def _create(
        goal, answered_at: datetime, correct: int = 2, size: int = 2, seconds: int = 5
    ):
        lesson_id = uuid.uuid4()
        for position in range(size):
            question = await question_factory(goal, text=f"q{position}-{lesson_id}")
            answer = await answer_factory(
                question,
                correct=position < correct,
                answered_at=answered_at,
                lesson_id=lesson_id,
                position=position,
            )
            answer.total_seconds = seconds
        await test_db.flush()
        return lesson_id

    return _create
