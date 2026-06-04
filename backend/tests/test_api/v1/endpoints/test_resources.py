import pytest
from backend.schemas.resource import ResourceResponse
from backend.models.resource import Resource, StudyResourceType
from backend.utils.envs import NUM_DIMENSIONS

@pytest.mark.asyncio
async def test_get_resources_successful(client, test_db, test_user):
    """Test that the resources endpoint returns a valid response for a valid request."""
    resource = Resource(
        goal_id=test_user.goal_id,
        objective_id=test_user.current_objective_id,
        resource_type=StudyResourceType.youtube,
        name="Python tutorial",
        description="A great python tutorial video",
        language="English",
        link="https://youtube.com/watch?v=123",
        description_embedding=[0.0] * NUM_DIMENSIONS
    )
    test_db.add(resource)
    await test_db.flush()
    await test_db.commit()
    await test_db.refresh(resource)
    
    response = await client.get(f"/api/v1/resources?goal_id={test_user.goal_id}")
    resource_response = ResourceResponse.model_validate(response.json())
    
    assert response.status_code == 200
    assert len(resource_response.resources) == 1
    assert resource_response.resources[0].name == "Python tutorial"
    assert resource_response.resources[0].id == str(resource.id)

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

    