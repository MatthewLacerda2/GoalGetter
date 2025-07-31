import pytest
from backend.schemas.roadmap import RoadmapInitiationResponse, RoadmapCreationResponse, RoadmapInitiationRequest, RoadmapCreationRequest, FollowUpQuestionsAndAnswers

@pytest.mark.asyncio
async def test_roadmap_initiation_success(client, mock_gemini_follow_up_questions):
    """Test that the roadmap initiation endpoint returns a valid response for a valid request."""
    
    test_request = RoadmapInitiationRequest(
        prompt_hint="Describe your goal in detail, including what you want to achieve",
        prompt="I want to learn Python. I just ran a 'hello world'. I wanna make apps"
    )
    
    response = await client.post("/api/v1/roadmap/initiation", json=test_request.model_dump())
        
    # Assert response status
    assert response.status_code == 200
    
    # Parse response
    response_data = response.json()
    
    # Validate schema
    validated_response = RoadmapInitiationResponse.model_validate(response_data)
    
@pytest.mark.asyncio
async def test_roadmap_creation_success(client, mock_gemini_roadmap_creation):
    """Test that the roadmap creation endpoint returns a valid response for a valid request."""
    
    test_request = RoadmapCreationRequest(
        prompt="I want to learn Python. I just ran a 'hello world'. I wanna make apps",
        questions_answers=[
            FollowUpQuestionsAndAnswers(question="What is your current skill level in this area?", answer="I just ran a hello world"),
            FollowUpQuestionsAndAnswers(question="What do you want to do with it?", answer="Create a Minecraft server")
        ]
    )
    
    response = await client.post("/api/v1/roadmap/creation", json=test_request.model_dump())
    
    # Assert response status
    assert response.status_code == 200
    
    # Parse response
    response_data = response.json()
    
    # Validate schema
    validated_response = RoadmapCreationResponse.model_validate(response_data)
    