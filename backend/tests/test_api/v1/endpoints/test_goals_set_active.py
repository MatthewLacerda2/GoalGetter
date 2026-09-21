import uuid
import pytest


def endpoint(goal_id):
    return f"/api/v1/goals/{goal_id}/set-active"


@pytest.mark.asyncio
async def test_set_active_switches_the_active_goal(auth_client, test_db, test_user, goal_factory):
    await goal_factory(test_user, active=True)
    other = await goal_factory(test_user, name="Guitar")

    response = await auth_client.put(endpoint(other.id))

    assert response.status_code == 200
    assert response.json() == {"goal_id": str(other.id)}
    await test_db.refresh(test_user)
    assert test_user.current_goal_id == other.id


@pytest.mark.asyncio
async def test_set_active_someone_elses_goal_is_404(auth_client, test_db, test_user, student_factory, goal_factory):
    mine = await goal_factory(test_user, active=True)
    other = await student_factory(email="o@example.com", google_id="other")
    theirs = await goal_factory(other)

    for goal_id in (theirs.id, uuid.uuid4()):
        assert (await auth_client.put(endpoint(goal_id))).status_code == 404
    await test_db.refresh(test_user)
    assert test_user.current_goal_id == mine.id


@pytest.mark.asyncio
async def test_set_active_requires_auth(client):
    assert (await client.put(endpoint(uuid.uuid4()))).status_code == 403
