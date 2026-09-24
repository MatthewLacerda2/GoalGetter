import pytest

from backend.api.v1.endpoints.tutor import MAX_PAGE_SIZE

ENDPOINT = "/api/v1/tutor/messages"


@pytest.mark.asyncio
async def test_history_is_newest_first_and_paginates(
    auth_client, test_user, goal_factory, exchange_factory
):
    goal = await goal_factory(test_user, active=True)
    await exchange_factory(goal, count=5)

    first = (await auth_client.get(ENDPOINT, params={"limit": 2})).json()
    assert [e["prompt"] for e in first] == ["q4", "q3"]
    assert first[0]["responses"] == ["a4", "b4"]
    second = (
        await auth_client.get(ENDPOINT, params={"limit": 2, "before": first[-1]["created_at"]})
    ).json()
    assert [e["prompt"] for e in second] == ["q2", "q1"]


@pytest.mark.asyncio
async def test_history_is_only_the_active_goal(
    auth_client, test_user, student_factory, goal_factory, exchange_factory
):
    goal = await goal_factory(test_user, active=True)
    await exchange_factory(await goal_factory(test_user, name="Chess"))
    await exchange_factory(
        await goal_factory(await student_factory(email="o@x.com", google_id="o"))
    )
    await exchange_factory(goal)
    body = (await auth_client.get(ENDPOINT)).json()
    assert len(body) == 1


@pytest.mark.asyncio
async def test_history_caps_the_limit(auth_client, test_user, goal_factory):
    await goal_factory(test_user, active=True)
    response = await auth_client.get(ENDPOINT, params={"limit": MAX_PAGE_SIZE + 1})
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_history_without_active_goal_is_404(auth_client):
    response = await auth_client.get(ENDPOINT)
    assert response.status_code == 404
    assert response.json()["detail"] == "No active goal"
