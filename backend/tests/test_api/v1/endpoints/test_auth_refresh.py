import pytest
from datetime import datetime, timedelta
from backend.models.refresh_token import RefreshToken

@pytest.mark.asyncio
async def test_refresh_success(client, test_db, test_user):
    """Test successful token refresh using a valid refresh token"""
    token_str = "valid_refresh_token_xyz"
    db_token = RefreshToken(
        student_id=test_user.id,
        token=token_str,
        expires_at=datetime.now() + timedelta(days=30),
        revoked=False
    )
    test_db.add(db_token)
    await test_db.commit()

    response = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": token_str}
    )
    assert response.status_code == 200
    res_data = response.json()
    assert "access_token" in res_data
    assert "refresh_token" in res_data
    assert res_data["refresh_token"] != token_str

@pytest.mark.asyncio
async def test_refresh_revoked_or_invalid(client):
    """Test refresh fails with invalid or nonexistent token"""
    response = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": "nonexistent_token"}
    )
    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid or expired refresh token"
