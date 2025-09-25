import pytest
from backend.schemas.student import TokenResponse

@pytest.mark.asyncio
async def test_login_successful(client, test_user, mock_google_verify):
    """Test successful login with valid Google token for existing user"""
    
    response = await client.post(
        "/api/v1/auth/login",
        json={"access_token": "fixture_user_token"}
    )
    
    token_response = TokenResponse.model_validate(response.json())
    
    assert response.status_code == 201
    assert isinstance(token_response, TokenResponse)
    assert token_response.student.email == test_user.email
    assert token_response.student.name == test_user.name
    assert token_response.student.google_id == test_user.google_id

@pytest.mark.asyncio
async def test_login_nonexistent_user(client, mock_google_verify, test_db):
    """Test login attempt with Google account that hasn't signed up"""
    
    mock_google_verify.return_value = {
        'email': 'nonexistent@example.com',
        'sub': 'nonexistent_google_id',
        'name': 'Nonexistent User'
    }
    
    response = await client.post(
        "/api/v1/auth/login",
        json={"access_token": "valid_google_token"}
    )
    
    assert response.status_code == 404
    assert response.json()["detail"] == "User not found"

@pytest.mark.asyncio
async def test_login_invalid_token(client, mock_google_verify):
    """Test login with invalid Google token"""
    mock_google_verify.side_effect = Exception("Invalid token")
    
    response = await client.post(
        "/api/v1/auth/login",
        json={"access_token": "invalid_token"}
    )
    
    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid Google token"

@pytest.mark.asyncio
async def test_login_missing_token(client):
    """Test login without providing token"""
    response = await client.post(
        "/api/v1/auth/login",
        json={}
    )
    
    assert response.status_code == 422

@pytest.mark.asyncio
async def test_delete_account_successful(client, mock_google_verify, test_user):
    """Test successful account deletion with valid token"""
    
    mock_google_verify.return_value = {
        'email': test_user.email,
        'sub': test_user.google_id,
        'name': test_user.name
    }
    
    login_response = await client.post("/api/v1/auth/login", json={"access_token": "fixture_user_token"})
    access_token = login_response.json()["access_token"]
    
    response = await client.delete(
        "/api/v1/auth/account",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 204
    
    login_response = await client.post(
        "/api/v1/auth/login",
        json={"access_token": "fixture_user_token"}
    )
    assert login_response.status_code == 404

@pytest.mark.asyncio
async def test_delete_account_invalid_token(client):
    """Test account deletion with invalid token"""
    response = await client.delete(
        "/api/v1/auth/account",
        headers={"Authorization": "Bearer invalid_token"}
    )
    
    assert response.status_code == 401
    assert response.json()["detail"] == "Could not validate credentials"