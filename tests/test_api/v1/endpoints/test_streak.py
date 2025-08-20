import pytest

@pytest.mark.asyncio
async def test_get_week_streak_no_student(client, test_db):
    """Test getting week streak for non-existent student returns 404"""
    response = await client.get("/api/v1/streak/non-existent-id/week")
    
    assert response.status_code == 404
    assert response.json()["detail"] == "Student not found"

@pytest.mark.asyncio
async def test_get_week_streak_with_student(client, test_db, test_user):
    """Test getting week streak for existing student with streak days"""
    
    response = await client.get(f"/api/v1/streak/{test_user.id}/week")
    
    assert response.status_code == 200