"""The frontier table's two promises (#133).

A goal always has exactly one current frontier, and the first exists from
creation - so nothing downstream ever handles "no frontier yet". And a frontier
is never edited or deleted: a change is a new row, and the history reads back
in order.

"Never edited" is read here as the history: the row that was current before a
move is still in the table, with the definition it always had. The refusal to
delete is asserted against the repository rather than against a caller, because
it is the repository that has to refuse - a caller that never tries is not
evidence of anything.
"""

from datetime import UTC, datetime, timedelta

import pytest

from backend.models.frontier import Frontier
from backend.repositories.frontier_repository import FrontierRepository


async def history(test_db, goal) -> list[str]:
    return [row.definition for row in await FrontierRepository(test_db).list_by_goal(goal.id)]


@pytest.mark.asyncio
async def test_a_new_goal_has_exactly_one_frontier_and_it_is_its_description(
    test_db, test_user, goal_factory
):
    """Day one: what he asked for and what we teach him are the same sentence"""
    goal = await goal_factory(test_user, description="Understand circuits.")

    assert await history(test_db, goal) == ["Understand circuits."]
    current = await FrontierRepository(test_db).current(goal.id)
    assert current.definition == "Understand circuits."


@pytest.mark.asyncio
async def test_the_first_frontier_is_dated_with_the_goal_not_with_tonight(
    test_db, test_user, goal_factory
):
    """A goal seeded into the past is not taught from a target dated today"""
    past = datetime.now(UTC) - timedelta(days=30)
    goal = await goal_factory(test_user, created_at=past, updated_at=past)

    current = await FrontierRepository(test_db).current(goal.id)
    assert current.created_at == past


@pytest.mark.asyncio
async def test_a_goal_with_no_description_still_has_a_frontier(test_db, test_user, goal_factory):
    """As empty as what it was written from - but there, so no reader branches"""
    goal = await goal_factory(test_user, description=None)

    assert await history(test_db, goal) == [""]


@pytest.mark.asyncio
async def test_the_current_frontier_is_the_newest_and_the_history_stays_in_order(
    test_db, test_user, goal_factory
):
    """Appending is not replacing: where he started is still readable"""
    goal = await goal_factory(test_user, description="Understand circuits.")
    repository = FrontierRepository(test_db)
    for definition in ("Build a doorbell board.", "Robotics."):
        await repository.create(Frontier(goal_id=goal.id, definition=definition))

    assert await repository.current(goal.id) is not None
    assert (await repository.current(goal.id)).definition == "Robotics."
    assert await history(test_db, goal) == [
        "Understand circuits.",
        "Build a doorbell board.",
        "Robotics.",
    ]


@pytest.mark.asyncio
async def test_a_frontier_is_never_deleted(test_db, test_user, goal_factory):
    """The history is where the student has been taken; it does not shrink"""
    goal = await goal_factory(test_user)
    repository = FrontierRepository(test_db)
    current = await repository.current(goal.id)

    with pytest.raises(NotImplementedError):
        await repository.delete(current.id)

    assert await repository.get_by_id(current.id) is not None
