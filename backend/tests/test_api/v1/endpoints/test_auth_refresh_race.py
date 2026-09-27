"""POST /auth/refresh under concurrency (#218), against the real test database.

The `client` fixture shares one transaction-bound session between requests, which
serializes them and never commits: a race cannot happen there. These tests give
every request its own session on its own connection and commit for real, the way
production does, then delete what they made.
"""

import asyncio
import uuid
from unittest.mock import patch

import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from backend.core.config import settings
from backend.core.database import AsyncSessionLocal, get_db
from backend.main import app
from backend.models.refresh_token import RefreshToken
from backend.models.student import Student
from backend.tests.fixtures.database import test_engine

SESSION_SETTINGS = {k: v for k, v in AsyncSessionLocal.kw.items() if k != "bind"}


@pytest_asyncio.fixture
async def committing_client(setup_test_db):
    """A client whose every request opens its own committing session, signed in as
    a fictitious student who is deleted afterwards (his tokens go by cascade)."""

    async def own_session():
        async with AsyncSession(test_engine, **SESSION_SETTINGS) as session:
            yield session

    app.dependency_overrides[get_db] = own_session
    transport = ASGITransport(app=app)
    name = f"Race {uuid.uuid4().hex[:8]}"
    try:
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            with patch.object(settings, "DEV_LOGIN", True):
                signed_in = await client.post("/api/v1/auth/dev-login", json={"name": name})
            student_id = uuid.UUID(signed_in.json()["student"]["id"])
            yield client, signed_in.json()["refresh_token"], student_id
    finally:
        app.dependency_overrides.clear()
        async with AsyncSession(test_engine, **SESSION_SETTINGS) as session:
            student = await session.get(Student, student_id)
            await session.delete(student)
            await session.commit()


async def _refresh(client, token):
    return await client.post("/api/v1/auth/refresh", json={"refresh_token": token})


async def _rows(student_id):
    async with AsyncSession(test_engine, **SESSION_SETTINGS) as session:
        stmt = select(func.count()).where(RefreshToken.student_id == student_id)
        return await session.scalar(stmt)


async def test_two_concurrent_refreshes_with_one_token_yield_one_pair(committing_client):
    """Before #218 both passed the `revoked` check and both got a pair. Now one
    wins; the other finds the token already rotated, which is a replay, so it is
    refused and also revokes the winner's successor (`token_rotation`)."""
    client, token, student_id = committing_client
    first, second = await asyncio.gather(_refresh(client, token), _refresh(client, token))

    assert sorted([first.status_code, second.status_code]) == [200, 401]
    assert await _rows(student_id) == 2  # the sign-in token and one successor
