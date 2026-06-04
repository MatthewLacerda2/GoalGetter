import pytest
from datetime import datetime, timezone
from backend.models.streak_day import StreakDay
from backend.schemas.streak import TimePeriodStreak

@pytest.mark.asyncio
async def test_get_week_streak_no_student(client):
    """Test getting week streak for non-existent student returns 404"""
    response = await client.get("/api/v1/streak/00000000-0000-0000-0000-000000000000/week")
    assert response.status_code == 404
    assert response.json()["detail"] == "Student not found"

@pytest.mark.asyncio
async def test_get_week_streak_with_student(client, test_db, test_user):
    """Test getting week streak for existing student with streak days"""
    streak_day = StreakDay(
        student_id=test_user.id,
        date_time=datetime.now(timezone.utc),
        xp=10
    )
    test_db.add(streak_day)
    test_user.current_streak = 3
    await test_db.flush()
    await test_db.commit()
    
    response = await client.get(f"/api/v1/streak/{test_user.id}/week")
    response_data = TimePeriodStreak.model_validate(response.json())
    
    assert response.status_code == 200
    assert response_data.current_streak == 3
    assert len(response_data.streak_days) == 1
    assert response_data.streak_days[0].id == str(streak_day.id)
