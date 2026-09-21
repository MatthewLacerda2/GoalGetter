import pytest

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
    auth_client, test_user, goal_factory, finished_lesson_factory
):
    goal = await goal_factory(test_user, name="Italian", rating=1215, active=True)
    await finished_lesson_factory(goal, days_ago(1, hour=9), elo_after=1195, elo_delta=-5)
    last = await finished_lesson_factory(
        goal, days_ago(1, hour=18), elo_after=1215, elo_delta=20, accuracy=100.0, seconds=90
    )
    await finished_lesson_factory(goal, None)

    body = (await auth_client.get(ENDPOINT)).json()

    yesterday = days_ago(1).date().isoformat()
    assert (body["goal_name"], body["current_elo"], body["current_streak"]) == ("Italian", 1215, 1)
    assert body["elo_history"] == [{"date": yesterday, "elo": 1215}]
    assert len(body["recent_lessons"]) == 2
    assert body["recent_lessons"][0] == {
        "lesson_id": str(last.id), "date": yesterday, "accuracy": 100.0,
        "elo_delta": 20, "duration_seconds": 90,
    }


@pytest.mark.asyncio
async def test_home_reads_only_the_active_goal(
    auth_client, test_user, goal_factory, finished_lesson_factory
):
    active = await goal_factory(test_user, active=True)
    other = await goal_factory(test_user, name="Chess")
    await finished_lesson_factory(other, days_ago(0), elo_after=1500)
    await finished_lesson_factory(active, days_ago(2), elo_after=1210)

    body = (await auth_client.get(ENDPOINT)).json()

    assert [p["elo"] for p in body["elo_history"]] == [1210]
    assert len(body["recent_lessons"]) == 1
    assert body["current_streak"] == 1
