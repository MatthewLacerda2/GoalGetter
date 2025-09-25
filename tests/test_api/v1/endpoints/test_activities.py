import pytest
from backend.utils.envs import NUM_QUESTIONS_PER_LESSON
from backend.schemas.activity import MultipleChoiceActivityResponse, MultipleChoiceActivityEvaluationRequest

@pytest.mark.asyncio
async def test_take_multiple_choice_activity_success(authenticated_client_with_objective, mock_gemini_multiple_choice_questions):
    """Test that the activities endpoint returns a valid response."""
    
    client, access_token = authenticated_client_with_objective
    
    response = await client.post(
        "/api/v1/activities",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 201
    
    activity_response = MultipleChoiceActivityResponse.model_validate(response.json())
    assert isinstance(activity_response, MultipleChoiceActivityResponse)
    assert len(activity_response.questions) >= NUM_QUESTIONS_PER_LESSON

@pytest.mark.asyncio
async def test_take_multiple_choice_activity_unauthorized(client):
    """Test that the activities endpoint returns 403 without token."""
    response = await client.post("/api/v1/activities")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_take_multiple_choice_activity_invalid_token(client, mock_google_verify):
    """Test that the activities endpoint returns 401 with invalid token."""
    mock_google_verify.side_effect = Exception("Invalid token")
    
    response = await client.post(
        "/api/v1/activities",
        headers={"Authorization": "Bearer invalid_token"}
    )
    assert response.status_code == 401

@pytest.mark.asyncio
async def test_evaluate_multiple_choice_activity_invalid_token(client, mock_google_verify):
    """Test that the evaluate activities endpoint returns 401 with invalid token."""
    mock_google_verify.side_effect = Exception("Invalid token")
    
    response = await client.post(
        "/api/v1/activities/evaluate",
        headers={"Authorization": "Bearer invalid_token"}
    )
    assert response.status_code == 401

@pytest.mark.asyncio
async def test_evaluate_multiple_choice_activity_unauthorized(client, mock_google_verify):
    """Test that the evaluate activities endpoint returns 403 without token."""
    mock_google_verify.side_effect = Exception("Invalid token")
    
    response = await client.post("/api/v1/activities/evaluate")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_evaluate_multiple_choice_activity_success(authenticated_client_with_objective):
    """Test that the evaluate activities endpoint returns a valid response."""
    
    client, access_token = authenticated_client_with_objective
    
    response = await client.post(
        "/api/v1/activities/evaluate",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 201
    
    activity_response = MultipleChoiceActivityEvaluationRequest.model_validate(response.json())
    assert isinstance(activity_response, MultipleChoiceActivityEvaluationRequest)
    assert len(activity_response.questions) >= NUM_QUESTIONS_PER_LESSON