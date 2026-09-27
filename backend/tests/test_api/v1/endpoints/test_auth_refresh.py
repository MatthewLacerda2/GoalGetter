"""POST /auth/refresh: rotation, reuse detection, and what is stored (#218)."""

from datetime import timedelta

from backend.core import clock
from backend.repositories.refresh_token_repository import RefreshTokenRepository
from backend.services.auth import token_rotation


async def _refresh(client, token):
    return await client.post("/api/v1/auth/refresh", json={"refresh_token": token})


async def _stored(test_db, token):
    return await RefreshTokenRepository(test_db).get_by_digest(token_rotation.digest(token))


async def test_refresh_success(client, test_db, test_user):
    """A live token is exchanged for a new pair, and stops being live."""
    token = await token_rotation.issue(test_db, test_user.id)
    await test_db.commit()

    response = await _refresh(client, token)
    assert response.status_code == 200
    assert "access_token" in response.json()
    assert response.json()["refresh_token"] != token
    assert (await _stored(test_db, token)).revoked is True


async def test_refresh_revoked_or_invalid(client):
    """Test refresh fails with invalid or nonexistent token"""
    response = await _refresh(client, "nonexistent_token")
    assert response.status_code == 401
    assert response.json()["code"] == "invalid_refresh_token"


async def test_replaying_a_rotated_token_revokes_its_successors(client, test_db, test_user):
    """The first token comes back after two rotations: it is refused, and so is
    everything issued after it - the family is over."""
    first = await token_rotation.issue(test_db, test_user.id)
    await test_db.commit()
    second = (await _refresh(client, first)).json()["refresh_token"]
    third = (await _refresh(client, second)).json()["refresh_token"]

    assert (await _refresh(client, first)).status_code == 401
    assert (await _refresh(client, third)).status_code == 401
    assert (await _stored(test_db, third)).revoked is True


async def test_replay_leaves_other_families_alone(client, test_db, test_user):
    """Another sign-in (another device) is another family, and keeps working."""
    stolen = await token_rotation.issue(test_db, test_user.id)
    other_device = await token_rotation.issue(test_db, test_user.id)
    await test_db.commit()
    await _refresh(client, stolen)

    assert (await _refresh(client, stolen)).status_code == 401
    assert (await _refresh(client, other_device)).status_code == 200


async def test_an_expired_token_is_refused_without_revoking_anything(client, test_db, test_user):
    token = await token_rotation.issue(test_db, test_user.id)
    stored = await _stored(test_db, token)
    stored.expires_at = clock.now() - timedelta(seconds=1)
    await test_db.commit()

    assert (await _refresh(client, token)).status_code == 401
    assert (await _stored(test_db, token)).revoked is False


async def test_no_token_is_stored_in_plaintext(client, test_db, test_user):
    """What the app holds never appears in the table, at sign-in or on rotation;
    the row holds its SHA-256."""
    token = await token_rotation.issue(test_db, test_user.id)
    await test_db.commit()
    rotated = (await _refresh(client, token)).json()["refresh_token"]

    for plaintext in (token, rotated):
        assert await RefreshTokenRepository(test_db).get_by_digest(plaintext) is None
        assert (await _stored(test_db, plaintext)).token == token_rotation.digest(plaintext)
