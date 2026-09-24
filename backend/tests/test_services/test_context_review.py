"""The context step's review: Gemini says what went stale (#90).

The step is exercised directly rather than through the chain, because what is
under test is one decision - what to do with the answer that comes back - and
running the two steps after it would only add noise to the evidence.

A standing context is never deleted. Every test here that expects a retirement
also checks the row is still in the table: it is progression history the
student is meant to be able to read.
"""

import pytest

from backend.models.student_context import StudentContext
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.jobs.steps.context import run_context_step
from backend.tests.fixtures.jobs import chain_gemini, review
from backend.tests.fixtures.lessons import at


async def studied(test_db, test_user, goal_factory, question_factory, answer_factory, *states):
    """A student with a lesson behind them and `states` standing readings,
    created oldest first - so the review sees them newest first, numbered."""
    goal = await goal_factory(test_user)
    question = await question_factory(goal, text="What is 'ciao'?")
    await answer_factory(question, correct=False, answered_at=at(10))
    written = [
        await StudentContextRepository(test_db).create(
            StudentContext(student_id=test_user.id, state=state, metacognition="Curious")
        )
        for state in states
    ]
    await test_db.commit()
    return written


async def standing(test_db, test_user) -> list[str]:
    return [c.state for c in await StudentContextRepository(test_db).list_valid(test_user.id)]


async def still_there(test_db, context) -> bool:
    """The row is still selectable by its id - retired, not deleted. A SELECT
    that finds nothing is what a delete would look like from here."""
    row = await StudentContextRepository(test_db).get_by_id(context.id)
    return row is not None and row.is_still_valid is False


@pytest.mark.asyncio
async def test_nothing_outdated_and_nothing_new_is_a_no_op(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """The cheap answer #90 exists for: the reading still holds, so nothing moves"""
    await studied(test_db, test_user, goal_factory, question_factory, answer_factory, "Beginner")

    calls = []
    with chain_gemini(test_db, calls):
        assert await run_context_step(test_db, str(test_user.id)) is False

    assert [name for name, _ in calls] == ["review"]
    assert await standing(test_db, test_user) == ["Beginner"]


@pytest.mark.asyncio
async def test_an_outdated_context_is_retired_and_stays_in_the_table(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """is_still_valid goes false; the row does not go anywhere"""
    [beginner] = await studied(
        test_db, test_user, goal_factory, question_factory, answer_factory, "Beginner"
    )

    calls = []
    with chain_gemini(test_db, calls, reviewed=review(outdated=[0])):
        assert await run_context_step(test_db, str(test_user.id)) is True

    assert await standing(test_db, test_user) == []
    assert await still_there(test_db, beginner)


@pytest.mark.asyncio
async def test_a_new_context_is_stored_beside_the_one_it_did_not_retire(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """Adding is not replacing: a reading that still holds keeps standing"""
    await studied(test_db, test_user, goal_factory, question_factory, answer_factory, "Beginner")

    calls = []
    with chain_gemini(test_db, calls, reviewed=review(added=[("Reads music", "Impatient")])):
        assert await run_context_step(test_db, str(test_user.id)) is True

    assert sorted(await standing(test_db, test_user)) == ["Beginner", "Reads music"]


@pytest.mark.asyncio
async def test_the_contexts_reach_the_prompt_newest_first(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """The index the model answers with is a position in this list and nothing else"""
    await studied(
        test_db, test_user, goal_factory, question_factory, answer_factory, "Older", "Newer"
    )

    calls = []
    with chain_gemini(test_db, calls, reviewed=review(outdated=[1])):
        await run_context_step(test_db, str(test_user.id))

    assert [c.state for c in dict(calls)["review"][1]] == ["Newer", "Older"]
    assert await standing(test_db, test_user) == ["Newer"]


@pytest.mark.asyncio
async def test_an_index_the_model_invented_or_repeated_is_dropped_not_raised(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """One reading was shown: index 7 does not exist, and 0 twice retires once"""
    [beginner] = await studied(
        test_db, test_user, goal_factory, question_factory, answer_factory, "Beginner"
    )

    calls = []
    with chain_gemini(test_db, calls, reviewed=review(outdated=[7, -1, 0, 0])):
        assert await run_context_step(test_db, str(test_user.id)) is True

    assert await standing(test_db, test_user) == []
    assert await still_there(test_db, beginner)


@pytest.mark.asyncio
async def test_a_student_with_no_reading_yet_still_gets_a_first_impression(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """Nothing to review: the step introduces the learner instead of reviewing"""
    await studied(test_db, test_user, goal_factory, question_factory, answer_factory)

    calls = []
    with chain_gemini(test_db, calls):
        assert await run_context_step(test_db, str(test_user.id)) is True

    assert [name for name, _ in calls] == ["context"]
    assert await standing(test_db, test_user) == ["Beginner"]
