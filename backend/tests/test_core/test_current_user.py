"""What a signed-in request answers when something fails on the way to the
student (#186). The app reads 401 as "your session ended" and signs the student
out (frontend/lib/core/api/api_client.dart), so only a token problem may say it.
"""

from datetime import timedelta
from unittest.mock import patch

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from backend.core.security import create_access_token
from backend.main import app
from backend.repositories.student_repository import StudentRepository

ENDPOINT = "/api/v1/me"
LOOKUP = "get_by_google_id"


@pytest_asyncio.fixture
async def server(auth_client):
    """The signed-in client, but a crash answers 500 as it does when served,
    instead of re-raising into the test."""
    transport = ASGITransport(app=app, raise_app_exceptions=False)
    async with AsyncClient(
        transport=transport, base_url="http://test", headers=auth_client.headers
    ) as ac:
        yield ac


@pytest.mark.asyncio
async def test_a_failing_student_lookup_does_not_sign_the_student_out(server):
    boom = RuntimeError("connection to server at 10.0.0.3 refused")
    with patch.object(StudentRepository, LOOKUP, side_effect=boom):
        response = await server.get(ENDPOINT)

    assert response.status_code == 500
    assert "10.0.0.3" not in response.text


@pytest.mark.asyncio
async def test_an_expired_token_still_answers_401(client, test_user):
    token = create_access_token({"sub": test_user.google_id}, timedelta(seconds=-1))
    response = await client.get(ENDPOINT, headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 401


@pytest.mark.asyncio
async def test_a_bad_token_still_answers_401(client):
    response = await client.get(ENDPOINT, headers={"Authorization": "Bearer not-a-jwt"})

    assert response.status_code == 401


@pytest.mark.asyncio
async def test_a_token_for_a_student_who_no_longer_exists_says_so(client):
    token = create_access_token({"sub": "a_deleted_google_id"})
    response = await client.get(ENDPOINT, headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 401
    assert response.json()["detail"] == "Student no longer exists"
