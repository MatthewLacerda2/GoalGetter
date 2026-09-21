import uuid
import pytest
from sqlalchemy import select
from backend.models.goal import Goal
from backend.models.resource import Resource, StudyResourceType


def endpoint(goal_id):
    return f"/api/v1/goals/{goal_id}"


async def add_resource(db, goal):
    db.add(Resource(
        goal_id=goal.id, resource_type=StudyResourceType.webpage, name="Site",
        description="A site", language="en", link="https://example.com",
    ))
    await db.flush()


@pytest.mark.asyncio
async def test_delete_active_goal_clears_it_and_its_resources(auth_client, test_db, test_user, goal_factory):
    goal = await goal_factory(test_user, active=True)
    await add_resource(test_db, goal)

    response = await auth_client.delete(endpoint(goal.id))

    assert response.status_code == 204
    await test_db.refresh(test_user)
    assert test_user.current_goal_id is None
    assert (await test_db.execute(select(Goal).where(Goal.id == goal.id))).first() is None
    assert (await test_db.execute(select(Resource).where(Resource.goal_id == goal.id))).first() is None


@pytest.mark.asyncio
async def test_delete_inactive_goal_keeps_the_active_one(auth_client, test_db, test_user, goal_factory):
    active = await goal_factory(test_user, active=True)
    other = await goal_factory(test_user, name="Guitar")

    assert (await auth_client.delete(endpoint(other.id))).status_code == 204
    await test_db.refresh(test_user)
    assert test_user.current_goal_id == active.id


@pytest.mark.asyncio
async def test_delete_someone_elses_goal_is_404(auth_client, test_db, student_factory, goal_factory):
    other = await student_factory(email="o@example.com", google_id="other")
    theirs = await goal_factory(other)

    for goal_id in (theirs.id, uuid.uuid4()):
        assert (await auth_client.delete(endpoint(goal_id))).status_code == 404
    assert (await test_db.execute(select(Goal).where(Goal.id == theirs.id))).first() is not None


@pytest.mark.asyncio
async def test_delete_requires_auth(client):
    assert (await client.delete(endpoint(uuid.uuid4()))).status_code == 403
