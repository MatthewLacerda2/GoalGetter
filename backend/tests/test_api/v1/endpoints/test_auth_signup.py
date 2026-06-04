import pytest
from backend.schemas.student import TokenResponse

@pytest.mark.asyncio
async def test_signup_new_user(client, mock_google_verify):
    """Test signing up a new user with a valid Google token"""
    mock_google_verify.side_effect = lambda token, request, client_id: {
        'email': 'new_user@example.com',
        'sub': 'new_google_id_123',
        'name': 'New User',
        'aud': client_id
    }
    response = await client.post(
        "/api/v1/auth/signup",
        headers={"Authorization": "Bearer valid_google_token"}
    )
    token_response = TokenResponse.model_validate(response.json())
    assert response.status_code == 201
    assert token_response.student.email == "new_user@example.com"

@pytest.mark.asyncio
async def test_signup_existing_user(client, mock_google_verify, test_user):
    """Test signing up with an existing Google account (login behavior)"""
    mock_google_verify.side_effect = lambda token, request, client_id: {
        'email': test_user.email,
        'sub': test_user.google_id,
        'name': test_user.name,
        'aud': client_id
    }
    response = await client.post(
        "/api/v1/auth/signup",
        headers={"Authorization": "Bearer fixture_user_token"}
    )
    token_response = TokenResponse.model_validate(response.json())
    assert response.status_code == 201
    assert token_response.student.email == test_user.email

@pytest.mark.asyncio
async def test_signup_invalid_token(client, mock_google_verify):
    """Test signing up with an invalid Google token"""
    mock_google_verify.side_effect = Exception("Invalid token")
    response = await client.post(
        "/api/v1/auth/signup",
        headers={"Authorization": "Bearer invalid_token"}
    )
    assert response.status_code == 401

@pytest.mark.asyncio
async def test_signup_missing_token(client):
    """Test signing up without providing an authorization header"""
    response = await client.post("/api/v1/auth/signup")
    assert response.status_code == 403
