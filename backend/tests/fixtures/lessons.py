from datetime import datetime, timedelta, timezone

import pytest

from backend.models.lesson import Lesson
from backend.models.lesson_answer import LessonAnswer
from backend.models.lesson_question import LessonQuestion

# A fixed clock for the lesson tests: `at(n)` is n minutes after it.
T0 = datetime(2026, 9, 1, tzinfo=timezone.utc)


def at(minutes: int) -> datetime:
    return T0 + timedelta(minutes=minutes)


@pytest.fixture
def question_factory(test_db):
    """A bank question for a goal. The correct choice is `correct` (default 0)."""
    async def _create(goal, text="Q?", correct=0, created_at=None):
        question = LessonQuestion(
            goal_id=goal.id, question=text, option_a="a", option_b="b", option_c="c",
            option_d="d", correct_option_index=correct, created_at=created_at or T0,
        )
        test_db.add(question)
        await test_db.flush()
        return question
    return _create


@pytest.fixture
def answer_factory(test_db):
    """An answer to `question`, right or wrong, given at `answered_at`, inside a
    finished lesson of its own."""
    async def _create(question, correct: bool, answered_at: datetime):
        lesson = Lesson(goal_id=question.goal_id, question_ids=[question.id], finished_at=answered_at)
        test_db.add(lesson)
        await test_db.flush()
        choice = question.correct_option_index if correct else (question.correct_option_index + 1) % 4
        answer = LessonAnswer(
            lesson_id=lesson.id, question_id=question.id, selected_option_index=choice,
            is_correct=correct, time_spent=5, created_at=answered_at,
        )
        test_db.add(answer)
        await test_db.flush()
        return answer
    return _create
