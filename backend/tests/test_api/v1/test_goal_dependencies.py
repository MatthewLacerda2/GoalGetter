import uuid
import pytest
from fastapi import HTTPException
from backend.api.v1.goal_dependencies import get_active_goal, get_owned_goal


@pytest.mark.asyncio
async def test_active_goal_is_returned(test_db, test_user, goal_factory):
    goal = await goal_factory(test_user, active=True)
    assert (await get_active_goal(current_user=test_user, db=test_db)).id == goal.id


@pytest.mark.asyncio
async def test_no_active_goal_is_404(test_db, test_user, goal_factory):
    await goal_factory(test_user)
    with pytest.raises(HTTPException) as err:
        await get_active_goal(current_user=test_user, db=test_db)
    assert err.value.status_code == 404


@pytest.mark.asyncio
async def test_owned_goal_is_returned(test_db, test_user, goal_factory):
    goal = await goal_factory(test_user)
    assert (await get_owned_goal(goal.id, current_user=test_user, db=test_db)).id == goal.id


@pytest.mark.asyncio
async def test_someone_elses_goal_is_404(test_db, test_user, student_factory, goal_factory):
    other = await student_factory(email="o@example.com", google_id="other")
    goal = await goal_factory(other)
    for goal_id in (goal.id, uuid.uuid4()):
        with pytest.raises(HTTPException) as err:
            await get_owned_goal(goal_id, current_user=test_user, db=test_db)
        assert err.value.status_code == 404
