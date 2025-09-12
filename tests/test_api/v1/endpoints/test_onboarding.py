import pytest
from backend.schemas.goal import GoalCreationFollowUpQuestionsRequest, GoalCreationFollowUpQuestionsResponse
#TODO: endpoint is now authorized, but tests are not updated
@pytest.mark.asyncio
async def test_onboarding_initiation_success(client, mock_gemini_follow_up_questions):
    """Test that the onboarding initiation endpoint returns a valid response for a valid request."""
    
    test_request = GoalCreationFollowUpQuestionsRequest(
        prompt_hint="Describe your goal in detail, including what you want to achieve",
        prompt="I want to learn Python. I just ran a 'hello world'. I wanna make apps"
    )
    
    response = await client.post("/api/v1/onboarding", json=test_request.model_dump())

    assert response.status_code == 200

    response_data = response.json()
    validated_response = GoalCreationFollowUpQuestionsResponse.model_validate(response_data)
    
    assert isinstance(validated_response, GoalCreationFollowUpQuestionsResponse)