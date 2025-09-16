import pytest
from backend.schemas.goal import GoalCreationFollowUpQuestionsRequest, GoalCreationFollowUpQuestionsResponse, GoalStudyPlanRequest, GoalFollowUpQuestionAndAnswer, GoalStudyPlanResponse

@pytest.mark.asyncio
async def test_generate_follow_up_questions_success(authenticated_client, mock_gemini_follow_up_questions):
    """Test that the onboarding initiation endpoint returns a valid response for a valid request."""
    
    client, access_token = authenticated_client
    
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
async def test_generate_study_plan_success(authenticated_client, mock_gemini_study_plan):
    """Test that the onboarding generate study plan endpoint returns a valid response for a valid request."""
    
    client, access_token = authenticated_client
    
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

    
@pytest.mark.asyncio
async def test_generate_follow_up_questions_user_already_has_goal(authenticated_client_with_objective):
    """Test that the onboarding initiation endpoint returns a 400 if the user already has a goal."""
    
    client, access_token = authenticated_client_with_objective
    
    test_request = GoalCreationFollowUpQuestionsRequest(
        prompt="I want to learn Python. I just ran a 'hello world'. I wanna make apps"
    )
    
    response = await client.post(
        "/api/v1/onboarding/follow_up_questions",
        headers={"Authorization": f"Bearer {access_token}"},
        json=test_request.model_dump()
    )
    
    assert response.status_code == 400

@pytest.mark.asyncio
async def test_generate_study_plan_user_already_has_goal(authenticated_client_with_objective):
    """Test that the onboarding generate study plan endpoint returns a 400 if the user already has a goal."""
    
    client, access_token = authenticated_client_with_objective
    
    test_request = GoalStudyPlanRequest(
        prompt="I want to learn Python. I just ran a 'hello world'. I wanna make apps",
        questions_answers=[GoalFollowUpQuestionAndAnswer(question="What is your current skill level in this area?", answer="I know the basics of Python")]
    )
    
    response = await client.post(
        "/api/v1/onboarding/study_plan",
        headers={"Authorization": f"Bearer {access_token}"},
        json=test_request.model_dump()
    )
    
    assert response.status_code == 400

@pytest.mark.asyncio
async def test_generate_follow_up_questions_unauthorized(client):
    """Test that the onboarding initiation endpoint returns a 403 without token."""
    
    response = await client.post("/api/v1/onboarding/follow_up_questions")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_generate_follow_up_questions_invalid_token(client, mock_google_verify):
    """Test that the onboarding initiation endpoint returns a 401 with invalid token."""
    
    mock_google_verify.side_effect = Exception("Invalid token")
    
    response = await client.post("/api/v1/onboarding/follow_up_questions", headers={"Authorization": "Bearer invalid_token"})
    assert response.status_code == 401
    
@pytest.mark.asyncio
async def test_generate_study_plan_unauthorized(client):
    """Test that the onboarding generate study plan endpoint returns a 403 without token."""
    response = await client.post("/api/v1/onboarding/study_plan")
    assert response.status_code == 403
    
@pytest.mark.asyncio
async def test_generate_study_plan_invalid_token(client, mock_google_verify):
    """Test that the onboarding generate study plan endpoint returns a 401 with invalid token."""
    
    mock_google_verify.side_effect = Exception("Invalid token")
    
    response = await client.post("/api/v1/onboarding/study_plan", headers={"Authorization": "Bearer invalid_token"})
    assert response.status_code == 401