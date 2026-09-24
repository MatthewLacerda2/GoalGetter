import uuid
import pytest
from backend.tests.fixtures.chat import exchange_factory  # noqa: F401


def like_url(exchange_id):
    return f"/api/v1/tutor/messages/{exchange_id}/like"


@pytest.mark.asyncio
async def test_like_then_unlike(auth_client, test_db, test_user, goal_factory, exchange_factory):
    [exchange] = await exchange_factory(await goal_factory(test_user, active=True))

    liked = await auth_client.put(like_url(exchange.id), json={"is_liked": True})
    assert liked.status_code == 200
    assert liked.json()["is_liked"] is True
    unliked = await auth_client.put(like_url(exchange.id), json={"is_liked": False})
    assert unliked.json()["is_liked"] is False
    await test_db.refresh(exchange)
    assert exchange.is_liked is False


@pytest.mark.asyncio
async def test_like_someone_elses_exchange_is_404(
    auth_client, test_user, student_factory, goal_factory, exchange_factory
):
    await goal_factory(test_user, active=True)
    other = await student_factory(email="o@example.com", google_id="other")
    [theirs] = await exchange_factory(await goal_factory(other, active=True))
    for exchange_id in (theirs.id, uuid.uuid4()):
        response = await auth_client.put(like_url(exchange_id), json={"is_liked": True})
        assert response.status_code == 404


@pytest.mark.asyncio
async def test_like_without_active_goal_is_404(auth_client, test_user, goal_factory, exchange_factory):
    [exchange] = await exchange_factory(await goal_factory(test_user))
    response = await auth_client.put(like_url(exchange.id), json={"is_liked": True})
    assert response.status_code == 404
