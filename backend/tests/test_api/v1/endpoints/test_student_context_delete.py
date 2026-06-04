import pytest
import uuid
from sqlalchemy import select
from backend.models.student_context import StudentContext

@pytest.mark.asyncio
async def test_delete_student_context_successful(auth_client, test_db, test_user, student_context_factory):
    """Test that delete student context endpoint deletes the context"""
    contexts = await student_context_factory(
        test_user.id,
        test_user.goal_id,
        test_user.current_objective_id,
        count=1
    )
    await test_db.commit()
    context_id = str(contexts[0].id)
    
    response = await auth_client.delete(f"/api/v1/student-context/{context_id}")
    assert response.status_code == 204
    
    # Verify it was deleted from the database
    query = select(StudentContext).where(StudentContext.id == uuid.UUID(context_id))
    deleted_context = (await test_db.execute(query)).scalar_one_or_none()
    assert deleted_context is None

@pytest.mark.asyncio
async def test_delete_student_context_unauthorized(client):
    """Test that delete student context endpoint returns 403 without token"""
    response = await client.delete(f"/api/v1/student-context/{uuid.uuid4()}")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_delete_student_context_not_found(auth_client):
    """Test that delete student context endpoint returns 404 for non-existent context"""
    response = await auth_client.delete(f"/api/v1/student-context/{uuid.uuid4()}")
    assert response.status_code == 404
    assert "not found" in response.json()["detail"].lower()

@pytest.mark.asyncio
async def test_delete_student_context_forbidden(auth_client, test_db, student_factory, goal_factory, objective_factory, student_context_factory):
    """Test that delete student context endpoint returns 403 for context owned by another student"""
    other_student = await student_factory(email="other@example.com", google_id="99999", name="Other User")
    other_goal = await goal_factory(student_id=other_student.id, name="Other Goal")
    other_objective = await objective_factory(goal_id=other_goal.id, name="Other Objective")
    
    other_contexts = await student_context_factory(
        other_student.id,
        other_goal.id,
        other_objective.id,
        count=1
    )
    await test_db.commit()
    
    response = await auth_client.delete(f"/api/v1/student-context/{other_contexts[0].id}")
    assert response.status_code == 403
    assert "does not belong" in response.json()["detail"].lower()
