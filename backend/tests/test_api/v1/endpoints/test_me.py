from datetime import datetime

import pytest

from backend.tests.fixtures.lessons import days_ago

ENDPOINT = "/api/v1/me"


@pytest.mark.asyncio
async def test_me_is_the_signed_in_students_profile(auth_client, test_user):
    response = await auth_client.get(ENDPOINT)

    assert response.status_code == 200
    body = response.json()
    assert body == {
        "id": str(test_user.id),
        "name": test_user.name,
        "email": test_user.email,
        "member_since": body["member_since"],
        "current_streak": 0,
    }
    assert datetime.fromisoformat(body["member_since"]) == test_user.created_at


@pytest.mark.asyncio
async def test_the_streak_is_user_wide_and_counts_days_with_an_answer(
    auth_client, test_user, goal_factory, lesson_factory
):
    """Two goals the same day count once; the streak spans every goal"""
    italian = await goal_factory(test_user, active=True)
    chess = await goal_factory(test_user, name="Chess")
    await lesson_factory(italian, days_ago(1))
    await lesson_factory(chess, days_ago(1, hour=15))
    await lesson_factory(chess, days_ago(2))

    response = await auth_client.get(ENDPOINT)

    assert response.json()["current_streak"] == 2


@pytest.mark.asyncio
async def test_me_needs_a_token(client):
    assert (await client.get(ENDPOINT)).status_code == 401
