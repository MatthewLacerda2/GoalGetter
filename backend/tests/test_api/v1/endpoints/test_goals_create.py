from unittest.mock import patch

import pytest
from sqlalchemy import select

from backend.models.goal import Goal
from backend.repositories.onboarding_repository import OnboardingRepository
from backend.services.onboarding.standard_questions import STANDARD_QUESTIONS, SYSTEM_AUTHOR
from backend.utils.envs import GEMINI_PREMIUM_MODEL

ENDPOINT = "/api/v1/goals"
CHAIN = "backend.api.v1.endpoints.goals.kickoff_student_chain"
BODY = {
    "prompt": "I want to learn guitar",
    "answers": [{"question": "Experience?", "answer": "None"}],
    "goal_name": "Play guitar",
    "description": "## Next up\nStart with open chords.",
}


@pytest.mark.asyncio
async def test_create_goal_persists_and_asks_the_standard_questions(
    auth_client, test_db, test_user
):
    """Authed commit: persists the goal, sets it active, fires the chain, and hands
    back the questions to ask while it runs (#132)"""
    with patch(CHAIN) as chain:
        response = await auth_client.post(ENDPOINT, json=BODY)

    assert response.status_code == 201
    body = response.json()
    assert body["name"] == "Play guitar"
    assert [q["key"] for q in body["standard_questions"]] == [q.key for q in STANDARD_QUESTIONS]
    assert body["standard_questions"][0]["options"] == [
        option.key for option in STANDARD_QUESTIONS[0].options
    ]

    goal = (await test_db.execute(select(Goal).where(Goal.id == body["id"]))).scalar_one()
    assert goal.student_id == test_user.id
    await test_db.refresh(test_user)
    assert str(test_user.current_goal_id) == body["id"]
    assert chain.call_args.args == (str(test_user.id),)


@pytest.mark.asyncio
async def test_create_goal_costs_no_gemini_call(auth_client):
    """The introduction screens were the one synchronous call here, and they are
    gone (#132): a premium call saved on every goal created"""
    with patch(CHAIN), patch("backend.api.v1.endpoints.goals.run_gemini") as gemini:
        response = await auth_client.post(ENDPOINT, json=BODY)

    assert response.status_code == 201
    gemini.assert_not_called()


@pytest.mark.asyncio
async def test_create_goal_requires_auth(client):
    """No Authorization header -> rejected, goal never created"""
    with patch(CHAIN) as chain:
        response = await client.post(ENDPOINT, json=BODY)
    assert response.status_code == 401
    chain.assert_not_called()


@pytest.mark.asyncio
async def test_create_goal_stores_the_onboarding_for_the_chain_to_read(
    auth_client, test_db, test_user
):
    """The answers are not handed to the chain, they are left where it reads them
    (#88). Each row says who wrote the question it holds (#132)"""
    with patch(CHAIN):
        response = await auth_client.post(ENDPOINT, json=BODY)

    assert response.status_code == 201
    rows = await OnboardingRepository(test_db).list_by_student(test_user.id)
    assert [(r.question, OnboardingRepository.answer_of(r), r.ai_model) for r in rows] == [
        ("What do you want to learn?", BODY["prompt"], SYSTEM_AUTHOR),
        ("Experience?", "None", GEMINI_PREMIUM_MODEL),
    ]
