import pytest
from unittest.mock import patch
from backend.services.gemini.onboarding.schema import GeminiStudyPlan

PLAN = GeminiStudyPlan(
    goal_name="Play guitar",
    description="## Next up\nStart with the basic **open chords** — they unlock most songs.",
)

ENDPOINT = "/api/v1/goals/study-plan"
GENERATE = "backend.api.v1.endpoints.goals.generate_study_plan"
BODY = {
    "prompt": "I want to learn guitar",
    "answers": [{"question": "How much experience do you have?", "answer": "None"}],
}


@pytest.mark.asyncio
async def test_study_plan_success(client):
    """Public endpoint (no auth): valid request -> goal name + markdown description"""
    with patch(GENERATE, return_value=PLAN) as gen:
        response = await client.post(ENDPOINT, json=BODY)
    assert response.status_code == 200
    body = response.json()
    assert body["goal_name"] == "Play guitar"
    assert "chords" in body["description"]
    gen.assert_called_once()


@pytest.mark.asyncio
async def test_study_plan_missing_answers(client):
    """Missing the required answers field -> 422 validation error"""
    response = await client.post(ENDPOINT, json={"prompt": "I want to learn guitar"})
    assert response.status_code == 422
