from datetime import timedelta

import pytest

from backend.core import clock
from backend.tests.fixtures.lessons import days_ago

ENDPOINT = "/api/v1/home"


@pytest.mark.asyncio
async def test_no_active_goal_is_404(auth_client, test_user, goal_factory):
    await goal_factory(test_user)
    response = await auth_client.get(ENDPOINT)
    assert response.status_code == 404
    assert response.json()["detail"] == "No active goal"


@pytest.mark.asyncio
async def test_home_is_the_active_goals_dashboard(
    auth_client, test_user, goal_factory, lesson_factory
):
    """A lesson on Home is the answers carrying one mark, counted together (#131)"""
    goal = await goal_factory(test_user, name="Italian", rating=1215, active=True)
    await lesson_factory(goal, days_ago(1, hour=9), correct=1, size=2, seconds=20)
    last = await lesson_factory(goal, days_ago(1, hour=18), correct=4, size=4, seconds=25)

    body = (await auth_client.get(ENDPOINT)).json()

    assert (body["goal_name"], body["current_elo"], body["current_streak"]) == ("Italian", 1215, 1)
    assert "elo_history" not in body
    assert len(body["recent_lessons"]) == 2
    assert body["recent_lessons"][0] == {
        "lesson_id": str(last),
        "date": clock.app_date(days_ago(1)).isoformat(),
        "accuracy": 100.0,
        "duration_seconds": 100,
    }


@pytest.mark.asyncio
async def test_home_reads_only_the_active_goal(
    auth_client, test_user, goal_factory, lesson_factory
):
    active = await goal_factory(test_user, active=True)
    other = await goal_factory(test_user, name="Chess")
    await lesson_factory(other, days_ago(0))
    await lesson_factory(active, days_ago(2))

    body = (await auth_client.get(ENDPOINT)).json()

    assert len(body["recent_lessons"]) == 1
    assert body["current_streak"] == 1


@pytest.mark.asyncio
async def test_an_answer_at_2200_brasilia_is_that_days_lesson(
    auth_client, test_user, goal_factory, question_factory, answer_factory
):
    """#92: 22:00 in Sao Paulo is 01:00 UTC the next day. The day is the student's."""
    goal = await goal_factory(test_user, active=True)
    yesterday = clock.today() - timedelta(days=1)
    late = clock.app_moment(yesterday, 22)
    await answer_factory(await question_factory(goal), correct=True, answered_at=late)

    body = (await auth_client.get(ENDPOINT)).json()

    assert body["recent_lessons"][0]["date"] == yesterday.isoformat()
    assert body["current_streak"] == 1
