import pytest
from backend.schemas.streak import XpByDaysResponse
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

#FIXME: this ain't workin'. it will once every user MUST have a goal and objective
@pytest.mark.asyncio
async def test_get_leaderboard_with_student(authenticated_client_with_objective):
    """Test getting the leaderboard with a student"""
    
    client, access_token = authenticated_client_with_objective
    
    response = await client.get(f"/api/v1/achievements/leaderboard", headers={"Authorization": f"Bearer {access_token}"})
    
    response_data = LeaderboardResponse.model_validate(response.json())
    
    assert response.status_code == 200
    assert isinstance(response_data, LeaderboardResponse)

@pytest.mark.asyncio
async def test_get_student_daily_xps(authenticated_client_with_objective):
    """Test getting the student's xp for an N number of days"""
    
    client, access_token = authenticated_client_with_objective
    
    response = await client.get(f"/api/v1/achievements/xp_by_days", headers={"Authorization": f"Bearer {access_token}"})
    
    response_data = XpByDaysResponse.model_validate(response.json())
    
    assert response.status_code == 200
    assert isinstance(response_data, XpByDaysResponse)