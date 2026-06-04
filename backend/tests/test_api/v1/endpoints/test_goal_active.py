import pytest

@pytest.mark.asyncio
async def test_set_active_goal_success(auth_client, test_db, test_user, goal_factory, objective_factory):
    """Test that PUT /goals/{goal_id}/set-active sets the active goal"""
    # Create a new goal with objective
    goal2 = await goal_factory(student_id=test_user.id, name="Second Goal")
    await objective_factory(goal_id=goal2.id, name="Objective 2")
    await test_db.commit()
    
    response = await auth_client.put(f"/api/v1/goals/{goal2.id}/set-active")
    assert response.status_code == 200
    response_data = response.json()
    assert response_data["goal_id"] == str(goal2.id)
    
    await test_db.refresh(test_user)
    assert test_user.goal_id == goal2.id

@pytest.mark.asyncio
async def test_set_active_goal_not_found(auth_client):
    """Test that PUT /goals/{goal_id}/set-active returns 404 for non-existent goal"""
    import uuid
    response = await auth_client.put(f"/api/v1/goals/{uuid.uuid4()}/set-active")
    assert response.status_code == 404
    assert "Goal not found" in response.json()["detail"]

@pytest.mark.asyncio
async def test_set_active_goal_forbidden(auth_client, test_db, student_factory, goal_factory):
    """Test that PUT /goals/{goal_id}/set-active returns 403 for goal belonging to another student"""
    other_student = await student_factory(email="other@example.com", google_id="99999", name="Other")
    other_goal = await goal_factory(student_id=other_student.id, name="Other Goal")
    await test_db.commit()
    
    response = await auth_client.put(f"/api/v1/goals/{other_goal.id}/set-active")
    assert response.status_code == 403
    assert "does not belong" in response.json()["detail"]
