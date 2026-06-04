import pytest
from backend.schemas.goal import GoalStudyPlanRequest, GoalStudyPlanResponse, GoalFollowUpQuestionAndAnswer
from backend.services.gemini.onboarding.schema import GeminiFollowUpValidation

@pytest.mark.asyncio
async def test_generate_study_plan_success(client, mock_google_verify, mock_gemini_study_plan, mock_gemini_follow_up_validation, test_db, student_factory):
    """Test that the onboarding generate study plan endpoint returns a valid response for a valid request."""
    await student_factory(email="test1@example.com", google_id="12345", name="Test User 1")
    await test_db.commit()
    
    request_body = GoalStudyPlanRequest(
        prompt="I want to learn Python. I just ran a 'hello world'. I wanna make apps",
        questions_answers=[GoalFollowUpQuestionAndAnswer(question="What is your current skill level in this area?", answer="I know the basics of Python")]
    )
    response = await client.post(
        "/api/v1/onboarding/study_plan",
        headers={"Authorization": "Bearer valid_google_token"},
        json=request_body.model_dump()
    )
    assert response.status_code == 201
    validated_response = GoalStudyPlanResponse.model_validate(response.json())
    assert isinstance(validated_response, GoalStudyPlanResponse)

@pytest.mark.asyncio
async def test_generate_study_plan_validation_failure(client, mock_google_verify, mock_gemini_follow_up_validation):
    """Test onboarding study plan validation failure returns 400 with reasoning"""
    mock_gemini_follow_up_validation.side_effect = lambda *args, **kwargs: GeminiFollowUpValidation(
        has_enough_information=True,
        makes_sense=False,
        is_harmless=True,
        is_achievable=True,
        reasoning="Unachievable or nonsensical study plan prompt"
    )
    request_body = GoalStudyPlanRequest(
        prompt="Nonsensical prompt",
        questions_answers=[GoalFollowUpQuestionAndAnswer(question="Question", answer="Answer")]
    )
    response = await client.post(
        "/api/v1/onboarding/study_plan",
        headers={"Authorization": "Bearer valid_google_token"},
        json=request_body.model_dump()
    )
    assert response.status_code == 400
    assert response.json()["detail"] == "Unachievable or nonsensical study plan prompt"
