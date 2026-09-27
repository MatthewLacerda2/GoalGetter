import uuid

from backend.models.chat_message import ChatMessage
from backend.repositories.chat_message_repository import ChatMessageRepository
from backend.tests.fixtures.chat import T0


async def test_list_by_goal_is_newest_first_before_cursor(
    test_db, test_user, goal_factory, exchange_factory
):
    goal = await goal_factory(test_user)
    rows = await exchange_factory(goal, count=4)
    await exchange_factory(await goal_factory(test_user, name="Chess"))
    repo = ChatMessageRepository(test_db)

    assert [r.prompt for r in await repo.list_by_goal(goal.id, 10)] == ["q3", "q2", "q1", "q0"]
    assert [r.prompt for r in await repo.list_by_goal(goal.id, 2, before=rows[2].created_at)] == [
        "q1",
        "q0",
    ]


async def test_exchanges_of_one_moment_come_back_highest_id_first(test_db, test_user, goal_factory):
    """The id breaks a tie in both newest-first reads. Written lowest id
    first - the order a read without the tie-break, or with it reversed, answers."""
    goal = await goal_factory(test_user)
    for key in (1, 2, 3):
        test_db.add(
            ChatMessage(
                id=uuid.UUID(int=key),
                student_id=test_user.id,
                goal_id=goal.id,
                prompt=f"q{key}",
                tutor_responses=["a"],
                created_at=T0,
            )
        )
        await test_db.flush()
    repo = ChatMessageRepository(test_db)

    assert [r.prompt for r in await repo.list_by_goal(goal.id, 10)] == ["q3", "q2", "q1"]
    assert [r.prompt for r in await repo.list_recent_by_student(test_user.id, 10)] == [
        "q3",
        "q2",
        "q1",
    ]


async def test_exchange_goes_with_its_goal(test_db, test_user, goal_factory, exchange_factory):
    """goal_id is ON DELETE CASCADE at the database level."""
    goal = await goal_factory(test_user)
    [row] = await exchange_factory(goal)
    await test_db.delete(goal)
    await test_db.flush()
    test_db.expunge(row)
    assert await ChatMessageRepository(test_db).get_by_id(row.id) is None
