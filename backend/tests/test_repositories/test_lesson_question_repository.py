import numpy as np
import pytest

from backend.repositories.lesson_question_repository import LessonQuestionRepository
from backend.tests.fixtures.lessons import at
from backend.utils.envs import NUM_DIMENSIONS


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

    history = {
        h.question.id: h for h in await LessonQuestionRepository(test_db).list_bank_history(goal.id)
    }

    assert (history[redeemed.id].last_was_correct, history[redeemed.id].last_answered_at) == (
        True,
        at(2),
    )
    assert (history[untouched.id].last_was_correct, history[untouched.id].last_answered_at) == (
        None,
        None,
    )


@pytest.mark.asyncio
async def test_bank_history_is_scoped_to_the_goal(
    test_db, test_user, goal_factory, question_factory
):
    goal, other = await goal_factory(test_user), await goal_factory(test_user, name="Chess")
    mine = await question_factory(goal)
    await question_factory(other)

    history = await LessonQuestionRepository(test_db).list_bank_history(goal.id)
    assert [h.question.id for h in history] == [mine.id]


@pytest.mark.asyncio
async def test_list_missing_embeddings_leaves_the_embedded_rows_in_the_database(
    test_db, test_user, goal_factory, question_factory
):
    """The backfill's queue is a query, not a scan (#96).

    The Python side already refuses to send a row whose column is filled, so
    nothing breaks if this WHERE goes - it just drags the whole table through
    memory and spends the per-run cap on rows there is no work for. That is
    what this pins.
    """
    goal = await goal_factory(test_user)
    done = await question_factory(goal, text="already embedded")
    done.question_embedding = np.zeros(NUM_DIMENSIONS, dtype=np.float32)
    pending = await question_factory(goal, text="still null")
    await test_db.flush()

    found = await LessonQuestionRepository(test_db).list_missing_embeddings(10)

    assert [row.id for row in found] == [pending.id]


@pytest.mark.asyncio
async def test_list_missing_embeddings_stops_at_the_cap_it_is_given(
    test_db, test_user, goal_factory, question_factory
):
    """What does not fit tonight is still null tomorrow, which is the queue"""
    goal = await goal_factory(test_user)
    for index in range(3):
        await question_factory(goal, text=f"Q{index}")
    await test_db.flush()

    assert len(await LessonQuestionRepository(test_db).list_missing_embeddings(2)) == 2
