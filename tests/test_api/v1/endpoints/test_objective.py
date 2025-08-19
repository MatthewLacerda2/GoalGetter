import pytest
from backend.schemas.objective import ObjectiveResponse

@pytest.mark.asyncio
async def test_get_objectives(client, mock_google_verify, test_db):
    """Test successful login with valid Google token for existing user"""
    #TODO: Implement this test