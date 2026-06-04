import pytest
from backend.schemas.goal import GoalCreationFollowUpQuestionsRequest, GoalCreationFollowUpQuestionsResponse
from backend.services.gemini.onboarding.schema import GeminiGoalValidation

@pytest.mark.asyncio
async def test_generate_follow_up_questions_success(client, mock_google_verify, mock_gemini_follow_up_questions, mock_gemini_prompt_validation):
    """Test that the onboarding initiation endpoint returns a valid response for a valid request."""
    request_body = GoalCreationFollowUpQuestionsRequest(
        prompt="I want to learn Python. I just ran a 'hello world'. I wanna make apps"
    )
    response = await client.post(
        "/api/v1/onboarding/follow_up_questions",
        headers={"Authorization": "Bearer valid_google_token"},
        json=request_body.model_dump(),
    )
    assert response.status_code == 201
    validated_response = GoalCreationFollowUpQuestionsResponse.model_validate(response.json())
    assert isinstance(validated_response, GoalCreationFollowUpQuestionsResponse)

@pytest.mark.asyncio
async def test_generate_follow_up_questions_validation_failure(client, mock_google_verify, mock_gemini_prompt_validation):
    """Test onboarding initiation validation failure returns 400 with reasoning"""
    mock_gemini_prompt_validation.side_effect = lambda *args, **kwargs: GeminiGoalValidation(
        makes_sense=False,
        is_harmless=True,
        is_achievable=True,
        reasoning="Harmful or invalid prompt details"
    )
    request_body = GoalCreationFollowUpQuestionsRequest(prompt="Harmful/invalid goal prompt")
    response = await client.post(
        "/api/v1/onboarding/follow_up_questions",
        headers={"Authorization": "Bearer valid_google_token"},
        json=request_body.model_dump(),
    )
    assert response.status_code == 400
    assert response.json()["detail"] == "Harmful or invalid prompt details"
