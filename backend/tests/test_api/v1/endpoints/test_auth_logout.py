from backend.repositories.refresh_token_repository import RefreshTokenRepository
from backend.services.auth import token_rotation


async def test_logout_success(client, test_db, test_user):
    """Test successful logout revokes the refresh token"""
    token = await token_rotation.issue(test_db, test_user.id)
    await test_db.commit()

    response = await client.post("/api/v1/auth/logout", json={"refresh_token": token})
    assert response.status_code == 204

    stored = await RefreshTokenRepository(test_db).get_by_digest(token_rotation.digest(token))
    assert stored.revoked is True
    refused = await client.post("/api/v1/auth/refresh", json={"refresh_token": token})
    assert refused.status_code == 401
