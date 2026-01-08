import pytest
from backend.schemas.student import TokenResponse
from backend.schemas.goal import GoalFollowUpQuestionAndAnswer, GoalStudyPlanResponse, GoalFullCreationRequest
from backend.schemas.goal import GoalCreationFollowUpQuestionsRequest, GoalCreationFollowUpQuestionsResponse, GoalStudyPlanRequest

full_creation_request = GoalFullCreationRequest(
    goal_name="Create a Python Application",
    goal_description="Create a Python App for Data Science",
    first_objective_name="Create a Bare Minimum Python Script",
    first_objective_description="Learn Programming Fundamentals to create a bare minimum Python script"
)

@pytest.mark.asyncio
async def test_generate_follow_up_questions_success(client, mock_google_verify, mock_gemini_follow_up_questions, mock_gemini_prompt_validation):
    """Test that the onboarding initiation endpoint returns a valid response for a valid request."""
    
    follow_up_questions_request = GoalCreationFollowUpQuestionsRequest(
        prompt="I want to learn Python. I just ran a 'hello world'. I wanna make apps"
    )
    
    response = await client.post(
        "/api/v1/onboarding/follow_up_questions",
        headers={"Authorization": "Bearer valid_google_token"},
        json=follow_up_questions_request.model_dump(),
    )

    assert response.status_code == 201
    response_data = response.json()
    validated_response = GoalCreationFollowUpQuestionsResponse.model_validate(response_data)
    assert isinstance(validated_response, GoalCreationFollowUpQuestionsResponse)

@pytest.mark.asyncio
async def test_generate_study_plan_success(client, mock_google_verify, mock_gemini_study_plan, mock_gemini_follow_up_validation):
    """Test that the onboarding generate study plan endpoint returns a valid response for a valid request."""
    
    study_plan_request = GoalStudyPlanRequest(
        prompt="I want to learn Python. I just ran a 'hello world'. I wanna make apps",
        questions_answers=[GoalFollowUpQuestionAndAnswer(question="What is your current skill level in this area?", answer="I know the basics of Python")]
    )
    
    response = await client.post(
        "/api/v1/onboarding/study_plan",
        headers={"Authorization": "Bearer valid_google_token"},
        json=study_plan_request.model_dump()
    )
    
    assert response.status_code == 201
    response_data = response.json()
    validated_response = GoalStudyPlanResponse.model_validate(response_data)
    assert isinstance(validated_response, GoalStudyPlanResponse)

@pytest.mark.asyncio
async def test_generate_full_creation_success(client, mock_google_verify, mock_gemini_embeddings, test_db):
    """Test that the onboarding generate full creation endpoint returns a valid response for a valid request."""
        
    response = await client.post(
        "/api/v1/onboarding/full_creation",
        headers={"Authorization": "Bearer valid_google_token"},
        json=full_creation_request.model_dump()
    )
    
    assert response.status_code == 201
    response_data = response.json()
    validated_response = TokenResponse.model_validate(response_data)
    assert isinstance(validated_response, TokenResponse)
    assert validated_response.student.email == "test1@example.com"
    assert validated_response.student.name == "Test User 1"
    assert validated_response.student.google_id == "12345"

@pytest.mark.asyncio
async def test_generate_full_creation_invalid_token(client, mock_google_verify):
    """Test full creation with invalid Google token"""
    mock_google_verify.side_effect = Exception("Invalid token")
    
    response = await client.post(
        "/api/v1/onboarding/full_creation",
        headers={"Authorization": "Bearer invalid_token"},
        json=full_creation_request.model_dump()
    )
    
    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid Google token"

@pytest.mark.asyncio
async def test_generate_full_creation_existing_user(client, mock_google_verify, mock_gemini_embeddings, test_db):
    """Test full creation attempt with existing Google account"""
    
    first_response = await client.post(
        "/api/v1/onboarding/full_creation",
        headers={"Authorization": "Bearer valid_google_token"},
        json=full_creation_request.model_dump()
    )
    
    second_response = await client.post(
        "/api/v1/onboarding/full_creation",
        headers={"Authorization": "Bearer valid_google_token"},
        json=full_creation_request.model_dump()
    )
    
    assert second_response.status_code == 409
    assert second_response.json()["detail"] == "User already exists"

@pytest.mark.asyncio
async def test_generate_full_creation_missing_token(client):
    """Test full creation without providing token"""
    
    response = await client.post(
        "/api/v1/onboarding/full_creation",
        json=full_creation_request.model_dump()
    )
    
    assert response.status_code == 403