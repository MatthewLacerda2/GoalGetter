import pytest
from backend.schemas.student import StudentCurrentStatusResponse
from backend.schemas.goal import GoalCreationFollowUpQuestionsRequest, GoalCreationFollowUpQuestionsResponse, GoalStudyPlanRequest
from backend.schemas.goal import GoalFollowUpQuestionAndAnswer, GoalStudyPlanResponse, GoalFullCreationRequest

@pytest.mark.asyncio
async def test_generate_follow_up_questions_success(authenticated_client, mock_gemini_follow_up_questions, mock_gemini_prompt_validation):
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
async def test_generate_study_plan_success(authenticated_client, mock_gemini_study_plan, mock_gemini_follow_up_validation):
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
async def test_generate_full_creation_success(authenticated_client, mock_gemini_embeddings):
    """Test that the onboarding generate full creation endpoint returns a valid response for a valid request."""
    
    client, access_token = authenticated_client
    
    test_request = GoalFullCreationRequest(
        goal_name="Create a Python Application",
        goal_description="Create a Python App for Data Science",
        first_objective_name="Create a Bare Minimum Python Script",
        first_objective_description="Learn Programming Fundamentals to create a bare minimum Python script"
    )
    
    response = await client.post(
        "/api/v1/onboarding/full_creation",
        headers={"Authorization": f"Bearer {access_token}"},
        json=test_request.model_dump()
    )
    
    assert response.status_code == 201
    
    response_data = response.json()
    validated_response = StudentCurrentStatusResponse.model_validate(response_data)
    assert isinstance(validated_response, StudentCurrentStatusResponse)