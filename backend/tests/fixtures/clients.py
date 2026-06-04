import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from backend.main import app
from backend.core.database import get_db

@pytest_asyncio.fixture
async def client(test_db):
    """Async test client fixture with transaction-bound session"""
    async def override_get_db():
        yield test_db
    
    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()

@pytest_asyncio.fixture
async def auth_client(client, mock_google_verify, test_user):
    """Fixture that provides an authenticated client with Authorization header pre-set"""
    mock_google_verify.return_value = {
        'email': test_user.email,
        'sub': test_user.google_id,
        'name': test_user.name
    }
    
    login_response = await client.post(
        "/api/v1/auth/login",
        json={"access_token": "fixture_user_token"}
    )
    access_token = login_response.json()["access_token"]
    client.headers["Authorization"] = f"Bearer {access_token}"
    yield client

@pytest_asyncio.fixture
async def authenticated_client(auth_client):
    """Legacy fixture for backward compatibility returning (client, token) tuple"""
    auth_header = auth_client.headers.get("Authorization", "")
    access_token = auth_header.split(" ")[1] if " " in auth_header else ""
    return auth_client, access_token



