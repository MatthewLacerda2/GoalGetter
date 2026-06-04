import pytest
import uuid
from sqlalchemy import select
from backend.models.student_context import StudentContext
from backend.schemas.student_context import StudentContextItem, CreateStudentContextRequest

@pytest.mark.asyncio
async def test_create_student_context_successful(auth_client, test_db, test_user):
    """Test that create student context endpoint returns a valid response"""
    payload = CreateStudentContextRequest(context="This is a test context")
    response = await auth_client.post("/api/v1/student-context", json=payload.model_dump())
    assert response.status_code == 201
    context_response = StudentContextItem.model_validate(response.json())
    assert context_response.state == payload.context
    
    # Verify it was stored in the database
    query = select(StudentContext).where(StudentContext.id == uuid.UUID(context_response.id))
    stored_context = (await test_db.execute(query)).scalar_one()
    assert stored_context.state == payload.context
    assert stored_context.student_id == test_user.id

@pytest.mark.asyncio
async def test_create_student_context_unauthorized(client):
    """Test that create student context endpoint returns 403 without token"""
    payload = CreateStudentContextRequest(context="Test context")
    response = await client.post("/api/v1/student-context", json=payload.model_dump())
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_create_student_context_no_goal(auth_client, test_db, test_user):
    """Test that create student context returns 400 when user has no goal"""
    test_user.goal_id = None
    await test_db.commit()
    
    payload = CreateStudentContextRequest(context="Test context")
    response = await auth_client.post("/api/v1/student-context", json=payload.model_dump())
    assert response.status_code == 400
    assert "active goal" in response.json()["detail"].lower()
