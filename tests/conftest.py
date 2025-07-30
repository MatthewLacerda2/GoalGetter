import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from app.main import app


@pytest_asyncio.fixture
async def client():
    """Async test client fixture"""
    # Override the database dependency
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac
    # Clean up the override after the test
    app.dependency_overrides.clear()