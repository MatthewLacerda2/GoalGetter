import pytest
from backend.schemas.activity import MultipleChoiceActivityResponse

@pytest.mark.asyncio
async def test_get_activities_success(client, mock_google_verify, test_user):
    """Test that the activities endpoint returns a valid response for a user with a goal."""
    
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
    
    response = await client.post(
        "/api/v1/activities",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 201
    
    activity_response = MultipleChoiceActivityResponse.model_validate(response.json())
    assert isinstance(activity_response, MultipleChoiceActivityResponse)

@pytest.mark.asyncio
async def test_get_activities_unauthorized(client):
    """Test that the activities endpoint returns 403 without token."""
    response = await client.post("/api/v1/activities")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_get_activities_invalid_token(client, mock_google_verify):
    """Test that the activities endpoint returns 401 with invalid token."""
    mock_google_verify.side_effect = Exception("Invalid token")
    
    response = await client.post(
        "/api/v1/activities",
        headers={"Authorization": "Bearer invalid_token"}
    )
    assert response.status_code == 401

@pytest.mark.asyncio
async def test_get_activities_no_goal(client, mock_google_verify, test_user):
    """Test that the activities endpoint returns 400 when student has no goal."""

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
    
    response = await client.post(
        "/api/v1/activities",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 400
    assert "goal" in response.json()["detail"].lower()