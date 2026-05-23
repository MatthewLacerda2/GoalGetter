import pytest
from backend.schemas.resource import ResourceResponse
import logging

logger = logging.getLogger(__name__)

@pytest.mark.asyncio
async def test_get_resources_successful(client, test_db):
    """Test that the resources endpoint returns a valid response for a valid request."""
    
    response = await client.get("/api/v1/resources?goal_id=00000000-0000-0000-0000-000000000000")
    
    resource_response = ResourceResponse.model_validate(response.json())
    
    assert response.status_code == 200
    assert isinstance(resource_response, ResourceResponse)


@pytest.mark.asyncio
async def test_get_resources_missing_goal_id(client):
    """Test getting resources without goal_id query parameter returns 422"""
    response = await client.get("/api/v1/resources")
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_get_resources_invalid_goal_id_format(client):
    """Test getting resources with invalid UUID format returns 422"""
    response = await client.get("/api/v1/resources?goal_id=not-a-uuid")
    assert response.status_code == 422
    