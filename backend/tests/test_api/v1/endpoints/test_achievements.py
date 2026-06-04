import pytest
from backend.schemas.streak import XpByDaysResponse
from backend.schemas.player_achievement import PlayerAchievementResponse, LeaderboardResponse

@pytest.mark.asyncio
async def test_get_achievements_with_student(client, test_user):
    """Test getting achievements for a student"""
    response = await client.get(f"/api/v1/achievements/{test_user.id}?limit=10")
    response_data = PlayerAchievementResponse.model_validate(response.json())
    assert response.status_code == 200
    assert isinstance(response_data, PlayerAchievementResponse)
    
@pytest.mark.asyncio
async def test_get_achievements_with_no_student(client):
    """Test getting achievements for a non-existent student returns 404"""
    response = await client.get("/api/v1/achievements/00000000-0000-0000-0000-000000000000?limit=10")
    assert response.status_code == 404
    assert response.json()["detail"] == "Student not found"

@pytest.mark.asyncio
async def test_get_leaderboard_with_student(auth_client):
    """Test getting the leaderboard with an authenticated student"""
    response = await auth_client.get("/api/v1/achievements/leaderboard")
    response_data = LeaderboardResponse.model_validate(response.json())
    assert response.status_code == 200
    assert isinstance(response_data, LeaderboardResponse)

@pytest.mark.asyncio
async def test_get_leaderboard_unauthorized(client):
    """Test that the leaderboard endpoint returns 403 without token."""
    response = await client.get("/api/v1/achievements/leaderboard")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_get_student_daily_xps(auth_client):
    """Test getting the student's xp for daily tracking"""
    response = await auth_client.get("/api/v1/achievements/xp_by_days")
    response_data = XpByDaysResponse.model_validate(response.json())
    assert response.status_code == 200
    assert isinstance(response_data, XpByDaysResponse)

@pytest.mark.asyncio
async def test_get_student_daily_xps_unauthorized(client):
    """Test that getting daily XP without auth header returns 403"""
    response = await client.get("/api/v1/achievements/xp_by_days")
    assert response.status_code == 403