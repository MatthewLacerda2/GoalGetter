from unittest.mock import patch

import pytest
from google.genai.errors import APIError

from backend.services.gemini.onboarding.onboarding_prompts import ONBOARDING_QUESTIONS
from backend.services.gemini.onboarding.schema import (
    GeminiGoalValidation,
    OnboardingQuestionItem,
    OnboardingQuestions,
)
from backend.tests.fixtures.gemini_client import BLOCKED, fake_gemini

VALID = GeminiGoalValidation(
    makes_sense=True, is_harmless=True, is_achievable=True, reasoning="learn to play guitar"
)
INVALID = GeminiGoalValidation(
    makes_sense=False, is_harmless=True, is_achievable=True, reasoning="that is not a goal"
)

QUESTIONS = OnboardingQuestions(
    questions=[
        OnboardingQuestionItem(
            question=f"Q{i}", option_a="a", option_b="b", option_c="c", option_d="d"
        )
        for i in range(ONBOARDING_QUESTIONS)
    ],
    ai_model="gemini-wrote-these",
)

ENDPOINT = "/api/v1/goals/objective-questions"
VALIDATE = "backend.api.v1.endpoints.goals.get_prompt_validation"
GENERATE = "backend.api.v1.endpoints.goals.generate_onboarding_questions"


@pytest.mark.asyncio
async def test_objective_questions_valid_goal(client):
    """Public endpoint (no auth): valid goal -> 4-option questions"""
    with patch(VALIDATE, return_value=VALID), patch(GENERATE, return_value=QUESTIONS):
        response = await client.post(ENDPOINT, json={"prompt": "I want to learn guitar"})
    assert response.status_code == 200
    body = response.json()
    assert len(body) == ONBOARDING_QUESTIONS == 6
    assert body[0]["question"] == "Q0"
    assert body[0]["options"] == ["a", "b", "c", "d"]
    assert {q["ai_model"] for q in body} == {"gemini-wrote-these"}


@pytest.mark.asyncio
async def test_objective_questions_invalid_goal(client):
    """Invalid goal -> 400 with the validation reasoning, questions never generated"""
    with patch(VALIDATE, return_value=INVALID), patch(GENERATE) as gen:
        response = await client.post(ENDPOINT, json={"prompt": "asdfgh"})
    assert response.status_code == 400
    assert response.json()["detail"] == "that is not a goal"
    gen.assert_not_called()


@pytest.mark.asyncio
async def test_objective_questions_missing_prompt(client):
    """Missing prompt field -> 422 validation error"""
    response = await client.post(ENDPOINT, json={})
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_objective_questions_gemini_error_passthrough(client):
    """A Gemini API error is surfaced with its own status code, not a raw 500"""
    err = APIError.__new__(APIError)
    err.code = 429
    err.message = "RESOURCE_EXHAUSTED"
    with patch(VALIDATE, side_effect=err):
        response = await client.post(ENDPOINT, json={"prompt": "I want to learn guitar"})
    assert response.status_code == 429
    assert "RESOURCE_EXHAUSTED" in response.json()["detail"]


@pytest.mark.asyncio
async def test_a_blocked_prompt_is_a_502_not_a_500(client):
    """#216: Gemini answering with no text is its failure, named as such - and
    never a 401 or 403, which the app would read as being signed out"""
    with fake_gemini(BLOCKED):
        response = await client.post(ENDPOINT, json={"prompt": "I want to learn guitar"})

    assert response.status_code == 502
    assert response.json()["detail"] == "Gemini gave no usable answer"
