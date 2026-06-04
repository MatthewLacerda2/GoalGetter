import pytest

@pytest.mark.asyncio
async def test_delete_account_successful(auth_client, client):
    """Test successful account deletion with valid token"""
    response = await auth_client.delete("/api/v1/auth/account")
    assert response.status_code == 204
    
    # Verify account is deleted (subsequent login fails)
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
