# test_roadmap.py
import pytest
from backend.schemas.roadmap import RoadmapInitiationResponse

@pytest.mark.asyncio
async def test_roadmap_initiation_success(client, mock_gemini_follow_up_questions):
    """Test that the roadmap initiation endpoint returns a valid response for a valid request."""
    
    test_request = {
        "prompt_hint": "Describe your goal in detail, including what you want to achieve",
        "prompt": "I want to learn Python. I just ran a 'hello world'. I wanna make apps"
    }
    
    response = await client.post("/api/v1/roadmap/initiation", json=test_request)
        
    # Assert response status
    assert response.status_code == 200
    
    # Parse response
    response_data = response.json()
    
    # Validate schema
    validated_response = RoadmapInitiationResponse.model_validate(response_data)