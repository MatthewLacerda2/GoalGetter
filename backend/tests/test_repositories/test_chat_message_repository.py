import pytest
from backend.repositories.chat_message_repository import ChatMessageRepository
from backend.tests.fixtures.chat import exchange_factory  # noqa: F401


@pytest.mark.asyncio
async def test_list_by_goal_is_newest_first_before_cursor(test_db, test_user, goal_factory, exchange_factory):
    goal = await goal_factory(test_user)
    rows = await exchange_factory(goal, count=4)
    await exchange_factory(await goal_factory(test_user, name="Chess"))
    repo = ChatMessageRepository(test_db)

    assert [r.prompt for r in await repo.list_by_goal(goal.id, 10)] == ["q3", "q2", "q1", "q0"]
    assert [r.prompt for r in await repo.list_by_goal(goal.id, 2, before=rows[2].created_at)] == ["q1", "q0"]


@pytest.mark.asyncio
async def test_exchange_goes_with_its_goal(test_db, test_user, goal_factory, exchange_factory):
    """goal_id is ON DELETE CASCADE at the database level."""
    goal = await goal_factory(test_user)
    [row] = await exchange_factory(goal)
    await test_db.delete(goal)
    await test_db.flush()
    test_db.expunge(row)
    assert await ChatMessageRepository(test_db).get_by_id(row.id) is None
