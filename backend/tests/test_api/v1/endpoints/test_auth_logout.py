import pytest
from datetime import datetime, timedelta
from backend.models.refresh_token import RefreshToken

@pytest.mark.asyncio
async def test_logout_success(client, test_db, test_user):
    """Test successful logout revokes the refresh token"""
    token_str = "logout_test_token"
    db_token = RefreshToken(
        student_id=test_user.id,
        token=token_str,
        expires_at=datetime.now() + timedelta(days=30),
        revoked=False
    )
    test_db.add(db_token)
    await test_db.commit()

    response = await client.post(
        "/api/v1/auth/logout",
        json={"refresh_token": token_str}
    )
    assert response.status_code == 204

    # Verify token is indeed revoked in database
    await test_db.refresh(db_token)
    assert db_token.revoked is True
