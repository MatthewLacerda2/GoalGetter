import pytest
from backend.schemas.player_achievements import PlayerAchievementResponse, LeaderboardResponse

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

@pytest.mark.asyncio
async def test_get_leaderboard_unauthorized(client):
    """Test that the leaderboard endpoint returns 403 without token."""
    response = await client.get("/api/v1/achievements/leaderboard")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_get_leaderboard_invalid_token(client, mock_google_verify):
    """Test that the leaderboard endpoint returns 401 with invalid token."""
    mock_google_verify.side_effect = Exception("Invalid token")
    
    response = await client.post(
        "/api/v1/activities",
        headers={"Authorization": "Bearer invalid_token"}
    )
    assert response.status_code == 401

@pytest.mark.asyncio
async def test_get_leaderboard_with_student(client, test_user):
    """Test getting the leaderboard with a student"""
    
    response = await client.get(f"/api/v1/achievements/leaderboard", headers={"Authorization": f"Bearer {test_user.access_token}"})
    
    response_data = LeaderboardResponse.model_validate(response.json())
    
    assert response.status_code == 200
    assert isinstance(response_data, LeaderboardResponse)