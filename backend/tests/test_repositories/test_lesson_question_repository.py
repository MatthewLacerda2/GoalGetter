import pytest

from backend.repositories.lesson_question_repository import LessonQuestionRepository
from backend.tests.fixtures.lessons import at


@pytest.mark.asyncio
async def test_bank_history_reports_only_the_latest_answer(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """Wrong, then right: the question's history says right, at the later time"""
    goal = await goal_factory(test_user)
    redeemed = await question_factory(goal, "redeemed")
    untouched = await question_factory(goal, "untouched")
    await answer_factory(redeemed, correct=False, answered_at=at(1))
    await answer_factory(redeemed, correct=True, answered_at=at(2))

    history = {h.question.id: h for h in await LessonQuestionRepository(test_db).list_bank_history(goal.id)}

    assert (history[redeemed.id].last_was_correct, history[redeemed.id].last_answered_at) == (True, at(2))
    assert (history[untouched.id].last_was_correct, history[untouched.id].last_answered_at) == (None, None)


@pytest.mark.asyncio
async def test_bank_history_is_scoped_to_the_goal(
    test_db, test_user, goal_factory, question_factory
):
    goal, other = await goal_factory(test_user), await goal_factory(test_user, name="Chess")
    mine = await question_factory(goal)
    await question_factory(other)

    history = await LessonQuestionRepository(test_db).list_bank_history(goal.id)
    assert [h.question.id for h in history] == [mine.id]
