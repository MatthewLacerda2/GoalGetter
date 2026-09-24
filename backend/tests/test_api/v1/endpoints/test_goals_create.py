from unittest.mock import patch

import pytest
from sqlalchemy import select

from backend.models.goal import Goal
from backend.repositories.onboarding_repository import OnboardingRepository
from backend.services.gemini.onboarding.schema import (
    GeminiIntroductionScreen,
    GeminiIntroductionScreens,
    IntroIcon,
)

INTRO = GeminiIntroductionScreens(
    screens=[
        GeminiIntroductionScreen(
            icon=IntroIcon.rocket_launch, title="Let's go", text="Your journey starts now."
        ),
        GeminiIntroductionScreen(
            icon=IntroIcon.lightbulb, title="Bite-sized", text="A little every day adds up."
        ),
    ]
)

ENDPOINT = "/api/v1/goals"
INTRO_GEN = "backend.api.v1.endpoints.goals.generate_introduction_screens"
CHAIN = "backend.api.v1.endpoints.goals.kickoff_student_chain"
BODY = {
    "prompt": "I want to learn guitar",
    "answers": [{"question": "Experience?", "answer": "None"}],
    "goal_name": "Play guitar",
    "description": "## Next up\nStart with open chords.",
}


@pytest.mark.asyncio
async def test_create_goal_persists_and_returns_intro(auth_client, test_db, test_user):
    """Authed commit: persists the goal, sets it active, fires async jobs, returns intro screens"""
    with patch(INTRO_GEN, return_value=INTRO), patch(CHAIN) as chain:
        response = await auth_client.post(ENDPOINT, json=BODY)

    assert response.status_code == 201
    body = response.json()
    assert body["name"] == "Play guitar"
    assert len(body["introduction_screen_data"]) == 2
    assert body["introduction_screen_data"][0] == {
        "icon": "rocket_launch",
        "title": "Let's go",
        "text": "Your journey starts now.",
    }

    goal = (await test_db.execute(select(Goal).where(Goal.id == body["id"]))).scalar_one()
    assert goal.student_id == test_user.id
    await test_db.refresh(test_user)
    assert str(test_user.current_goal_id) == body["id"]
    chain.assert_called_once_with(str(test_user.id))


@pytest.mark.asyncio
async def test_create_goal_requires_auth(client):
    """No Authorization header -> rejected, goal never created"""
    with patch(INTRO_GEN) as intro:
        response = await client.post(ENDPOINT, json=BODY)
    assert response.status_code == 403
    intro.assert_not_called()


@pytest.mark.asyncio
async def test_create_goal_stores_the_onboarding_for_the_chain_to_read(
    auth_client, test_db, test_user
):
    """The answers are not handed to the chain, they are left where it reads them (#88)"""
    with patch(INTRO_GEN, return_value=INTRO), patch(CHAIN):
        response = await auth_client.post(ENDPOINT, json=BODY)

    assert response.status_code == 201
    rows = await OnboardingRepository(test_db).list_by_student(test_user.id)
    assert [(r.question, r.option_a, r.selected_option_index) for r in rows] == [
        ("What do you want to learn?", BODY["prompt"], None),
        ("Experience?", "None", 0),
    ]
