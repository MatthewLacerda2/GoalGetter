import pytest
from backend.schemas.goal import GoalCreationFollowUpQuestionsRequest, GoalCreationFollowUpQuestionsResponse, GoalStudyPlanRequest, GoalFollowUpQuestionAndAnswer, GoalStudyPlanResponse
#TODO: these endpoints are not being tested for authorization. Fix this
@pytest.mark.asyncio
async def test_generate_follow_up_questions_success(client, mock_gemini_follow_up_questions, mock_google_verify, test_user):
    """Test that the onboarding initiation endpoint returns a valid response for a valid request."""
    
    mock_google_verify.return_value = {
        'email': test_user.email,
        'sub': test_user.google_id,
        'name': test_user.name
    }
    
    login_response = await client.post(
        "/api/v1/auth/login",
        json={"access_token": "fixture_user_token"}
    )
    access_token = login_response.json()["access_token"]
    
    test_request = GoalCreationFollowUpQuestionsRequest(
        prompt="I want to learn Python. I just ran a 'hello world'. I wanna make apps"
    )
    
    response = await client.post(
        "/api/v1/onboarding/follow_up_questions",
        headers={"Authorization": f"Bearer {access_token}"},
        json=test_request.model_dump(),
    )

    assert response.status_code == 201

    response_data = response.json()
    validated_response = GoalCreationFollowUpQuestionsResponse.model_validate(response_data)
    
    assert isinstance(validated_response, GoalCreationFollowUpQuestionsResponse)

@pytest.mark.asyncio
async def test_generate_study_plan_success(client, mock_gemini_study_plan, mock_google_verify, test_user):
    """Test that the onboarding generate study plan endpoint returns a valid response for a valid request."""
    
    mock_google_verify.return_value = {
        'email': test_user.email,
        'sub': test_user.google_id,
        'name': test_user.name
    }
    
    login_response = await client.post(
        "/api/v1/auth/login",
        json={"access_token": "fixture_user_token"}
    )
    access_token = login_response.json()["access_token"]
    
    test_request = GoalStudyPlanRequest(
        prompt="I want to learn Python. I just ran a 'hello world'. I wanna make apps",
        questions_answers=[GoalFollowUpQuestionAndAnswer(question="What is your current skill level in this area?", answer="I know the basics of Python")]
    )
    
    response = await client.post(
        "/api/v1/onboarding/study_plan",
        headers={"Authorization": f"Bearer {access_token}"},
        json=test_request.model_dump()
    )
    
    assert response.status_code == 201
    
    response_data = response.json()
    validated_response = GoalStudyPlanResponse.model_validate(response_data)
    
    assert isinstance(validated_response, GoalStudyPlanResponse)