from datetime import UTC, datetime, timedelta

import pytest

from backend.repositories.goal_repository import GoalRepository


@pytest.mark.asyncio
async def test_updated_at_is_set_on_create(test_db, test_user, goal_factory):
    goal = await goal_factory(test_user)
    await test_db.refresh(goal)
    assert goal.updated_at is not None


@pytest.mark.asyncio
async def test_updated_at_moves_when_the_rating_changes(test_db, test_user, goal_factory):
    past = datetime.now(UTC) - timedelta(days=3)
    goal = await goal_factory(test_user, created_at=past, updated_at=past)

    goal.rating += 15
    await GoalRepository(test_db).update(goal)
    await test_db.refresh(goal)

    assert goal.updated_at > past + timedelta(days=2)


@pytest.mark.asyncio
async def test_list_by_student_is_newest_first(test_db, test_user, student_factory, goal_factory):
    now = datetime.now(UTC)
    other = await student_factory(email="o@example.com", google_id="other")
    await goal_factory(other, name="Not mine")
    await goal_factory(test_user, name="Old", created_at=now - timedelta(days=1))
    await goal_factory(test_user, name="New", created_at=now)

    goals = await GoalRepository(test_db).list_by_student(test_user.id)

    assert [g.name for g in goals] == ["New", "Old"]


@pytest.mark.asyncio
async def test_set_rating_is_one_update_that_returns_the_rating_written(
    test_db, test_user, goal_factory
):
    """The rating is replayed from the answers and written whole (#62), so the
    write is a value and not an increment - and it still moves `updated_at`."""
    past = datetime.now(UTC) - timedelta(days=3)
    goal = await goal_factory(test_user, rating=1200, created_at=past, updated_at=past)
    goals = GoalRepository(test_db)

    assert await goals.set_rating(goal.id, 1207) == 1207
    assert await goals.set_rating(goal.id, 1204) == 1204

    # The session's copy is in step: nothing stale is left to flush back.
    assert goal.rating == 1204
    await test_db.flush()
    await test_db.refresh(goal)
    assert goal.rating == 1204
    assert goal.updated_at > past + timedelta(days=2)
