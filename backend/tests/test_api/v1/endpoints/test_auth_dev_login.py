"""POST /auth/dev-login: the fictitious sign-in behind the DEV_LOGIN setting."""

from unittest.mock import patch

import pytest

from backend.core.config import settings
from backend.schemas.student import TokenResponse


@pytest.fixture
def dev_login_on():
    with patch.object(settings, "DEV_LOGIN", True):
        yield


@pytest.mark.asyncio
async def test_dev_login_off_is_404(client):
    """With DEV_LOGIN off (the default) the route answers as if it did not exist."""
    response = await client.post("/api/v1/auth/dev-login", json={"name": "Claude"})
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_dev_login_creates_a_fictitious_student(client, dev_login_on):
    response = await client.post("/api/v1/auth/dev-login", json={"name": "Claude"})
    assert response.status_code == 201
    student = TokenResponse.model_validate(response.json()).student
    assert student.name == "Fictitious Claude"
    assert student.google_id == "fictitious-claude"
    assert student.email == "fictitious-claude@fictitious.invalid"


@pytest.mark.asyncio
async def test_dev_login_reuses_the_same_student(client, dev_login_on):
    first = await client.post("/api/v1/auth/dev-login", json={"name": "Claude"})
    second = await client.post("/api/v1/auth/dev-login", json={"name": "Claude"})
    assert second.status_code == 201
    assert second.json()["student"]["id"] == first.json()["student"]["id"]
    assert second.json()["refresh_token"] != first.json()["refresh_token"]


@pytest.mark.asyncio
async def test_dev_login_does_not_double_the_prefix(client, dev_login_on):
    response = await client.post("/api/v1/auth/dev-login", json={"name": "Fictitious Ana"})
    assert response.json()["student"]["name"] == "Fictitious Ana"
    assert response.json()["student"]["google_id"] == "fictitious-ana"


@pytest.mark.asyncio
async def test_dev_login_token_opens_an_authed_route(client, dev_login_on):
    """The access token is a real session: an authed route accepts it."""
    login = await client.post("/api/v1/auth/dev-login", json={"name": "Claude"})
    token = login.json()["access_token"]
    response = await client.delete(
        "/api/v1/auth/account", headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 204


@pytest.mark.asyncio
async def test_dev_login_rejects_a_name_without_letters(client, dev_login_on):
    response = await client.post("/api/v1/auth/dev-login", json={"name": "  !! "})
    assert response.status_code == 422
