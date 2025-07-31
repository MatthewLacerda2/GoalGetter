import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from backend.main import app
from backend.schemas.roadmap import RoadmapInitiationResponse, RoadmapCreationResponse, Step
from unittest.mock import patch

@pytest_asyncio.fixture
async def client():
    """Async test client fixture"""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()
    
@pytest.fixture
def mock_gemini_follow_up_questions():
    """Fixture to mock Gemini follow-up questions responses"""
    
    def mock_get_gemini_follow_up_questions(*args, **kwargs):
        return RoadmapInitiationResponse(
            original_prompt="I want to learn Python. I just ran a 'hello world'. I wanna make apps",
            questions=["What is your current skill level in this area?", "How much time can you dedicate to this goal?", "What is your preferred learning style?", "Do you have any specific constraints or preferences?"]
        )

    # Patch where the function is imported and used, not where it's defined
    #TODO: the fixture should be for the api call from the gemini client, not for the function itself
    with patch('backend.api.v1.endpoints.roadmap.get_gemini_follow_up_questions', side_effect=mock_get_gemini_follow_up_questions) as mock:
        yield mock
        
@pytest.fixture
def mock_gemini_roadmap_creation():
    """Fixture to mock Gemini roadmap creation responses"""
    
    def mock_get_gemini_roadmap_creation(*args, **kwargs):
        
        steps = [
            Step(title="Learn Python", description="Learn the basics of Python"),
            Step(title="Learn Flask", description="Learn Flask"),
            Step(title="Create a Minecraft server", description="Create a Minecraft server"),
        ]
        
        return RoadmapCreationResponse(
            steps=steps,
            notes=["Use the Python documentation", "Use the Minecraft server documentation"]
        )
    
    # Patch where the function is imported and used, not where it's defined
    #TODO: the fixture should be for the api call from the gemini client, not for the function itself
    with patch('backend.api.v1.endpoints.roadmap.get_gemini_roadmap_creation', side_effect=mock_get_gemini_roadmap_creation) as mock:
        yield mock