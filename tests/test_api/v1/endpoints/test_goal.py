import pytest
from sqlalchemy import select
from backend.schemas.goal import ListGoalsResponse
from backend.models.goal import Goal
from backend.models.objective import Objective
from backend.models.student import Student
from datetime import datetime, timezone

@pytest.mark.asyncio
async def test_list_goals_success(authenticated_client_with_objective, test_db):
    """Test that GET /goals returns goals ordered by latest objective update"""
    client, access_token = authenticated_client_with_objective
    
    # Get the test user
    stmt = select(Student).where(Student.google_id == "test_google_id_123")
    result = await test_db.execute(stmt)
    student = result.scalar_one()
    
    # Create additional goals with objectives
    goal2 = Goal(
        student_id=student.id,
        name="Second Goal",
        description="Second Goal Description"
    )
    test_db.add(goal2)
    await test_db.commit()
    await test_db.refresh(goal2)
    
    # Create objective for goal2 with recent update
    objective2 = Objective(
        goal_id=goal2.id,
        name="Objective 2",
        description="Objective 2 Description",
        ai_model="gemini-2.5-flash",
        last_updated_at=datetime.now(timezone.utc)
    )
    test_db.add(objective2)
    await test_db.commit()
    await test_db.refresh(objective2)
    
    response = await client.get(
        "/api/v1/goals",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 200
    response_data = response.json()
    validated_response = ListGoalsResponse.model_validate(response_data)
    assert isinstance(validated_response, ListGoalsResponse)
    assert len(validated_response.goals) >= 2
    
    # Check that goals are ordered by latest objective update (most recent first)
    if len(validated_response.goals) >= 2:
        # The goal with the most recently updated objective should be first
        assert validated_response.goals[0].id == goal2.id


@pytest.mark.asyncio
async def test_set_active_goal_success(authenticated_client_with_objective, test_db):
    """Test that PUT /goals/{goal_id}/set-active sets the active goal"""
    client, access_token = authenticated_client_with_objective
    
    # Get the test user
    stmt = select(Student).where(Student.google_id == "test_google_id_123")
    result = await test_db.execute(stmt)
    student = result.scalar_one()
    
    # Create a new goal with objective
    goal2 = Goal(
        student_id=student.id,
        name="Second Goal",
        description="Second Goal Description"
    )
    test_db.add(goal2)
    await test_db.commit()
    await test_db.refresh(goal2)
    
    objective2 = Objective(
        goal_id=goal2.id,
        name="Objective 2",
        description="Objective 2 Description",
        ai_model="gemini-2.5-flash"
    )
    test_db.add(objective2)
    await test_db.commit()
    await test_db.refresh(objective2)
    
    response = await client.put(
        f"/api/v1/goals/{goal2.id}/set-active",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 200
    response_data = response.json()
    assert response_data["goal_id"] == goal2.id
    assert response_data["goal_name"] == goal2.name
    
    # Verify student's active goal was updated
    await test_db.refresh(student)
    assert student.goal_id == goal2.id
    assert student.current_objective_id == objective2.id


@pytest.mark.asyncio
async def test_set_active_goal_not_found(authenticated_client_with_objective):
    """Test that PUT /goals/{goal_id}/set-active returns 404 for non-existent goal"""
    client, access_token = authenticated_client_with_objective
    
    import uuid
    fake_goal_id = str(uuid.uuid4())
    
    response = await client.put(
        f"/api/v1/goals/{fake_goal_id}/set-active",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 404
    assert "Goal not found" in response.json()["detail"]


@pytest.mark.asyncio
async def test_set_active_goal_forbidden(authenticated_client_with_objective, test_db):
    """Test that PUT /goals/{goal_id}/set-active returns 403 for goal belonging to another student"""
    client, access_token = authenticated_client_with_objective
    
    # Create another student with a goal
    other_student = Student(
        email="other@example.com",
        google_id="99999",
        name="Other User"
    )
    test_db.add(other_student)
    await test_db.commit()
    await test_db.refresh(other_student)
    
    other_goal = Goal(
        student_id=other_student.id,
        name="Other Goal",
        description="Other Goal Description"
    )
    test_db.add(other_goal)
    await test_db.commit()
    await test_db.refresh(other_goal)
    
    response = await client.put(
        f"/api/v1/goals/{other_goal.id}/set-active",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 403
    assert "does not belong" in response.json()["detail"]


@pytest.mark.asyncio
async def test_delete_goal_success(authenticated_client_with_objective, test_db):
    """Test that DELETE /goals/{goal_id} deletes goal and doesn't decrement XP"""
    client, access_token = authenticated_client_with_objective
    
    # Get the test user
    stmt = select(Student).where(Student.google_id == "test_google_id_123")
    result = await test_db.execute(stmt)
    student = result.scalar_one()
    
    # Store original XP
    original_xp = student.overall_xp
    
    # Create a new goal with objective
    goal2 = Goal(
        student_id=student.id,
        name="Goal to Delete",
        description="This goal will be deleted"
    )
    test_db.add(goal2)
    await test_db.commit()
    await test_db.refresh(goal2)
    
    objective2 = Objective(
        goal_id=goal2.id,
        name="Objective to Delete",
        description="This objective will be deleted",
        ai_model="gemini-2.5-flash"
    )
    test_db.add(objective2)
    await test_db.commit()
    await test_db.refresh(objective2)
    
    response = await client.delete(
        f"/api/v1/goals/{goal2.id}",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 204
    
    # Verify goal was deleted
    goal_stmt = select(Goal).where(Goal.id == goal2.id)
    goal_result = await test_db.execute(goal_stmt)
    deleted_goal = goal_result.scalar_one_or_none()
    assert deleted_goal is None
    
    # Verify XP was NOT decremented
    await test_db.refresh(student)
    assert student.overall_xp == original_xp


@pytest.mark.asyncio
async def test_delete_goal_sets_null_if_active(authenticated_client_with_objective, test_db):
    """Test that DELETE /goals/{goal_id} sets goal_id to NULL if deleting active goal and no other goals exist"""
    client, access_token = authenticated_client_with_objective
    
    # Get the test user
    stmt = select(Student).where(Student.google_id == "test_google_id_123")
    result = await test_db.execute(stmt)
    student = result.scalar_one()
    
    # Get current active goal
    current_goal_id = student.goal_id
    
    if current_goal_id:
        # Verify this is the only goal for this student
        goals_stmt = select(Goal).where(Goal.student_id == student.id)
        goals_result = await test_db.execute(goals_stmt)
        all_goals = goals_result.scalars().all()
        
        # If there's only one goal, deleting it should set goal_id to NULL
        # If there are multiple goals, it should switch to another goal
        if len(all_goals) == 1:
            response = await client.delete(
                f"/api/v1/goals/{current_goal_id}",
                headers={"Authorization": f"Bearer {access_token}"}
            )
            
            assert response.status_code == 204
            
            # Verify student's goal_id and current_objective_id are now NULL
            await test_db.refresh(student)
            assert student.goal_id is None
            assert student.goal_name is None
            assert student.current_objective_id is None
            assert student.current_objective_name is None
        else:
            # Multiple goals exist - deleting active goal should switch to another goal
            response = await client.delete(
                f"/api/v1/goals/{current_goal_id}",
                headers={"Authorization": f"Bearer {access_token}"}
            )
            
            assert response.status_code == 204
            
            # Verify student's goal_id was updated to another goal (not NULL)
            await test_db.refresh(student)
            assert student.goal_id is not None
            assert student.goal_id != current_goal_id
            assert student.goal_name is not None


@pytest.mark.asyncio
async def test_delete_goal_not_found(authenticated_client_with_objective):
    """Test that DELETE /goals/{goal_id} returns 404 for non-existent goal"""
    client, access_token = authenticated_client_with_objective
    
    import uuid
    fake_goal_id = str(uuid.uuid4())
    
    response = await client.delete(
        f"/api/v1/goals/{fake_goal_id}",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 404
    assert "Goal not found" in response.json()["detail"]


@pytest.mark.asyncio
async def test_delete_goal_forbidden(authenticated_client_with_objective, test_db):
    """Test that DELETE /goals/{goal_id} returns 403 for goal belonging to another student"""
    client, access_token = authenticated_client_with_objective
    
    # Create another student with a goal
    other_student = Student(
        email="other@example.com",
        google_id="99999",
        name="Other User"
    )
    test_db.add(other_student)
    await test_db.commit()
    await test_db.refresh(other_student)
    
    other_goal = Goal(
        student_id=other_student.id,
        name="Other Goal",
        description="Other Goal Description"
    )
    test_db.add(other_goal)
    await test_db.commit()
    await test_db.refresh(other_goal)
    
    response = await client.delete(
        f"/api/v1/goals/{other_goal.id}",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 403
    assert "does not belong" in response.json()["detail"]


@pytest.mark.asyncio
async def test_list_goals_unauthorized(client):
    """Test that GET /goals returns 403 without token"""
    response = await client.get("/api/v1/goals")
    assert response.status_code == 403
