# test_roadmap.py
import pytest
from backend.schemas.roadmap import RoadmapInitiationResponse

@pytest.mark.asyncio
async def test_roadmap_initiation_success():
    """Test that the roadmap initiation endpoint returns a valid response for a valid request."""
    
    test_request = {
        "prompt_hint": "Describe your goal in detail, including what you want to achieve",
        "prompt": "I want to learn Python programming to build web applications and automate tasks"
    }
    
    response = await client.post("/api/v1/roadmap/initiation", json=test_request)
        
    # Assert response status
    assert response.status_code == 200
    
    # Parse response
    response_data = response.json()
    
    RoadmapInitiationResponse.model_validate(response_data)
    
    # Validate that original_prompt matches the input prompt
    assert response_data["original_prompt"] == test_request["prompt"]