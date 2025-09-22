import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from backend.main import app
from tests.fixtures.database import override_get_db
from backend.core.database import get_db

@pytest_asyncio.fixture
async def client():
    """Async test client fixture"""
    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()

@pytest_asyncio.fixture
async def authenticated_client(client, mock_google_verify, test_user):
    """Fixture that provides a logged-in client with access token for testing"""
    
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
    
    return client, access_token

@pytest_asyncio.fixture
async def authenticated_client_with_objective(client, mock_google_verify, test_user_with_objective):
    """Fixture that provides a logged-in client with access token for testing with user that has objective"""
    
    mock_google_verify.return_value = {
        'email': test_user_with_objective.email,
        'sub': test_user_with_objective.google_id,
        'name': test_user_with_objective.name
    }
    
    login_response = await client.post(
        "/api/v1/auth/login",
        json={"access_token": "fixture_user_token"}
    )
    access_token = login_response.json()["access_token"]
    
    return client, access_token
