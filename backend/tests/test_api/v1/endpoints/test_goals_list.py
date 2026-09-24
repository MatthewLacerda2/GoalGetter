from datetime import UTC, datetime, timedelta

import pytest

ENDPOINT = "/api/v1/goals"


@pytest.mark.asyncio
async def test_list_goals_carries_every_field(auth_client, test_user, goal_factory):
    goal = await goal_factory(test_user, active=True, rating=920)
    response = await auth_client.get(ENDPOINT)

    assert response.status_code == 200
    [body] = response.json()
    assert body["id"] == str(goal.id)
    assert body["name"] == "Learn Italian"
    assert body["description"] == "Hold a chat."
    assert body["current_elo"] == 920
    assert body["is_active"] is True
    assert body["created_at"] and body["updated_at"]


@pytest.mark.asyncio
async def test_list_goals_newest_first_and_one_active(auth_client, test_user, goal_factory):
    now = datetime.now(UTC)
    old = await goal_factory(test_user, name="Old", created_at=now - timedelta(days=2))
    new = await goal_factory(test_user, name="New", created_at=now, active=True)
    await goal_factory(test_user, name="Mid", created_at=now - timedelta(days=1))

    body = (await auth_client.get(ENDPOINT)).json()

    assert [g["name"] for g in body] == ["New", "Mid", "Old"]
    assert [g["is_active"] for g in body] == [True, False, False]
    assert (body[0]["id"], body[2]["id"]) == (str(new.id), str(old.id))


@pytest.mark.asyncio
async def test_list_goals_only_the_students_own(
    auth_client, test_user, student_factory, goal_factory
):
    other = await student_factory(email="o@example.com", google_id="other")
    await goal_factory(other, name="Not mine")
    await goal_factory(test_user, name="Mine")

    body = (await auth_client.get(ENDPOINT)).json()

    assert [g["name"] for g in body] == ["Mine"]


@pytest.mark.asyncio
async def test_list_goals_empty(auth_client):
    response = await auth_client.get(ENDPOINT)
    assert response.status_code == 200
    assert response.json() == []


@pytest.mark.asyncio
async def test_list_goals_requires_auth(client):
    assert (await client.get(ENDPOINT)).status_code == 403
