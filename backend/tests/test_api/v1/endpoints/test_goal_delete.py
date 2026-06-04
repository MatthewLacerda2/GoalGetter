import pytest
from sqlalchemy import select
from backend.models.goal import Goal

@pytest.mark.asyncio
async def test_delete_goal_success(auth_client, test_db, test_user, goal_factory, objective_factory):
    """Test that DELETE /goals/{goal_id} deletes goal and doesn't decrement XP"""
    original_xp = test_user.overall_xp
    goal2 = await goal_factory(student_id=test_user.id, name="Goal to Delete")
    await objective_factory(goal_id=goal2.id, name="Objective to Delete")
    await test_db.commit()
    
    response = await auth_client.delete(f"/api/v1/goals/{goal2.id}")
    assert response.status_code == 204
    
    # Verify goal was deleted
    stmt = select(Goal).where(Goal.id == goal2.id)
    deleted_goal = (await test_db.execute(stmt)).scalar_one_or_none()
    assert deleted_goal is None
    
    await test_db.refresh(test_user)
    assert test_user.overall_xp == original_xp

@pytest.mark.asyncio
async def test_delete_goal_sets_null_if_active_and_no_other_goals_exist(auth_client, test_db, test_user):
    """Test that DELETE /goals/{goal_id} sets goal_id to NULL if deleting active goal and no other goals exist"""
    current_goal_id = test_user.goal_id
    
    response = await auth_client.delete(f"/api/v1/goals/{current_goal_id}")
    assert response.status_code == 204
    
    await test_db.refresh(test_user)
    assert test_user.goal_id is None
    assert test_user.current_objective_id is None

@pytest.mark.asyncio
async def test_delete_active_goal_switches_to_another_goal(auth_client, test_db, test_user, goal_factory, objective_factory):
    """Test that DELETE /goals/{goal_id} switches to another goal if active goal is deleted but other goals exist"""
    current_goal_id = test_user.goal_id
    
    other_goal = await goal_factory(student_id=test_user.id, name="Other Goal")
    from datetime import datetime, timezone
    other_obj = await objective_factory(
        goal_id=other_goal.id, 
        name="Other Obj",
        last_updated_at=datetime.now(timezone.utc)
    )
    await test_db.commit()
    
    response = await auth_client.delete(f"/api/v1/goals/{current_goal_id}")
    assert response.status_code == 204
    
    await test_db.refresh(test_user)
    assert test_user.goal_id == other_goal.id
    assert test_user.current_objective_id == other_obj.id

@pytest.mark.asyncio
async def test_delete_goal_not_found(auth_client):
    """Test that DELETE /goals/{goal_id} returns 404 for non-existent goal"""
    import uuid
    response = await auth_client.delete(f"/api/v1/goals/{uuid.uuid4()}")
    assert response.status_code == 404

@pytest.mark.asyncio
async def test_delete_goal_forbidden(auth_client, test_db, student_factory, goal_factory):
    """Test that DELETE /goals/{goal_id} returns 403 for goal belonging to another student"""
    other_student = await student_factory(email="other@example.com", google_id="99999", name="Other")
    other_goal = await goal_factory(student_id=other_student.id, name="Other Goal")
    await test_db.commit()
    
    response = await auth_client.delete(f"/api/v1/goals/{other_goal.id}")
    assert response.status_code == 403
