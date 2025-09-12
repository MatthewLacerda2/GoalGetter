import pytest
from backend.schemas.player_achievements import PlayerAchievementResponse

@pytest.mark.asyncio
async def test_get_achievements_with_student(client, test_user):
    """Test getting achievements for a student"""
    
    response = await client.get(f"/api/v1/achievements/{test_user.id}?limit=10")
    
    response_data = PlayerAchievementResponse.model_validate(response.json())
    
    assert response.status_code == 200
    assert isinstance(response_data, PlayerAchievementResponse)
    
@pytest.mark.asyncio
async def test_get_achievements_with_no_student(client, test_db):
    """Test getting achievements for a non-existent student returns 404"""
    
    response = await client.get(f"/api/v1/achievements/non-existent-id?limit=10")
    
    assert response.status_code == 404
    assert response.json()["detail"] == "Student not found"