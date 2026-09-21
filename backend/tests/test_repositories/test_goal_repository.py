import pytest
from datetime import datetime, timedelta, timezone
from backend.repositories.goal_repository import GoalRepository


@pytest.mark.asyncio
async def test_updated_at_is_set_on_create(test_db, test_user, goal_factory):
    goal = await goal_factory(test_user)
    await test_db.refresh(goal)
    assert goal.updated_at is not None


@pytest.mark.asyncio
async def test_updated_at_moves_when_the_rating_changes(test_db, test_user, goal_factory):
    past = datetime.now(timezone.utc) - timedelta(days=3)
    goal = await goal_factory(test_user, created_at=past, updated_at=past)

    goal.rating += 15
    await GoalRepository(test_db).update(goal)
    await test_db.refresh(goal)

    assert goal.updated_at > past + timedelta(days=2)


@pytest.mark.asyncio
async def test_list_by_student_is_newest_first(test_db, test_user, student_factory, goal_factory):
    now = datetime.now(timezone.utc)
    other = await student_factory(email="o@example.com", google_id="other")
    await goal_factory(other, name="Not mine")
    await goal_factory(test_user, name="Old", created_at=now - timedelta(days=1))
    await goal_factory(test_user, name="New", created_at=now)

    goals = await GoalRepository(test_db).list_by_student(test_user.id)

    assert [g.name for g in goals] == ["New", "Old"]
