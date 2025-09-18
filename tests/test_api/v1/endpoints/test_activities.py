import pytest
from backend.schemas.activity import MultipleChoiceActivityResponse

@pytest.mark.asyncio
async def test_take_multiple_choice_activity_success(authenticated_client_with_objective):
    """Test that the activities endpoint returns a valid response for a user with a goal."""
    
    client, access_token = authenticated_client_with_objective
    
    response = await client.post(
        "/api/v1/activities",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 201
    
    activity_response = MultipleChoiceActivityResponse.model_validate(response.json())
    assert isinstance(activity_response, MultipleChoiceActivityResponse)
    #assert len(activity_response.questions) > 5 #TODO: uncomment this when we have AI creating the questions

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
async def test_take_multiple_choice_activity_no_goal(authenticated_client):
    """Test that the activities endpoint returns 400 when student has no goal."""

    client, access_token = authenticated_client
    
    response = await client.post(
        "/api/v1/activities",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 400
    assert response.json()["detail"] == "User did not finish the onboarding and does not have an objective."