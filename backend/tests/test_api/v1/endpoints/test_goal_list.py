import pytest
from backend.schemas.goal import ListGoalsResponse

@pytest.mark.asyncio
async def test_list_goals_success(auth_client, test_db, test_user, goal_factory, objective_factory):
    """Test that GET /goals returns goals ordered by latest objective update"""
    # Create additional goal with objective using factory
    goal2 = await goal_factory(student_id=test_user.id, name="Second Goal")
    from datetime import datetime, timezone
    await objective_factory(
        goal_id=goal2.id, 
        name="Objective 2",
        last_updated_at=datetime.now(timezone.utc)
    )
    await test_db.commit()
    
    response = await auth_client.get("/api/v1/goals")
    assert response.status_code == 200
    validated_response = ListGoalsResponse.model_validate(response.json())
    assert len(validated_response.goals) >= 2
    assert validated_response.goals[0].id == str(goal2.id)

@pytest.mark.asyncio
async def test_list_goals_unauthorized(client):
    """Test that GET /goals returns 403 without token"""
    response = await client.get("/api/v1/goals")
    assert response.status_code == 403
