import pytest
import uuid
from datetime import datetime
from sqlalchemy import select
from backend.models.student_context import StudentContext
from backend.models.student import Student
from backend.models.goal import Goal
from backend.models.objective import Objective
from backend.schemas.student_context import StudentContextResponse, StudentContextItem, CreateStudentContextRequest

def create_student_contexts(student_id, goal_id, objective_id, count=3):
    """Create a predefined array of student contexts for testing"""
    
    TEST_NAMESPACE = uuid.UUID('00000000-0000-0000-0000-000000000001')
    
    contexts = []
    for i in range(count):
        context = StudentContext(
            id=uuid.uuid5(TEST_NAMESPACE, f"Context {i}"),
            student_id=student_id,
            goal_id=goal_id,
            objective_id=objective_id,
            source="student",
            state=f"Test context state {i}",
            metacognition="",
            state_embedding=None,
            metacognition_embedding=None,
            ai_model="non-artificial",
            created_at=datetime.now(),
            is_still_valid=True
        )
        contexts.append(context)
    return contexts

@pytest.mark.asyncio
async def test_get_student_contexts_successful(authenticated_client_with_objective, test_db, test_user):
    """Test that get student contexts endpoint returns a valid response"""
    
    client, access_token = authenticated_client_with_objective
    
    contexts = create_student_contexts(
        test_user.id,
        test_user.goal_id,
        test_user.current_objective_id,
        count=3
    )
    
    for context in contexts:
        test_db.add(context)
    await test_db.commit()
    
    response = await client.get(
        "/api/v1/student-context",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    context_response = StudentContextResponse.model_validate(response.json())
    
    assert response.status_code == 200
    assert isinstance(context_response, StudentContextResponse)
    assert len(context_response.contexts) == 3
    assert all(isinstance(context, StudentContextItem) for context in context_response.contexts)

@pytest.mark.asyncio
async def test_get_student_contexts_unauthorized(client):
    """Test that get student contexts endpoint returns 403 without token"""
    
    response = await client.get("/api/v1/student-context")
    
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_get_student_contexts_no_objective(authenticated_client, test_db, test_user):
    """Test that get student contexts returns empty list when user has no objective"""
    
    client, access_token = authenticated_client
    
    # Ensure user has no objective
    test_user.current_objective_id = None
    await test_db.commit()
    
    response = await client.get(
        "/api/v1/student-context",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    context_response = StudentContextResponse.model_validate(response.json())
    
    assert response.status_code == 200
    assert isinstance(context_response, StudentContextResponse)
    assert len(context_response.contexts) == 0

@pytest.mark.asyncio
async def test_create_student_context_successful(authenticated_client_with_objective, test_db, test_user):
    """Test that create student context endpoint returns a valid response"""
    
    client, access_token = authenticated_client_with_objective
    
    payload = CreateStudentContextRequest(context="This is a test context")
    
    response = await client.post(
        "/api/v1/student-context",
        json=payload.model_dump(),
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    context_response = StudentContextItem.model_validate(response.json())
    
    assert response.status_code == 201
    assert isinstance(context_response, StudentContextItem)
    assert context_response.state == payload.context
    assert context_response.metacognition == ""
    assert context_response.id is not None
    assert context_response.created_at is not None
    
    # Verify it was stored in the database
    query = select(StudentContext).where(StudentContext.id == uuid.UUID(context_response.id))
    result = await test_db.execute(query)
    stored_context = result.scalars().first()
    
    assert stored_context is not None
    assert stored_context.state == payload.context
    assert stored_context.source == "student"
    assert stored_context.ai_model == "non-artificial"
    assert stored_context.student_id == test_user.id

@pytest.mark.asyncio
async def test_create_student_context_unauthorized(client):
    """Test that create student context endpoint returns 403 without token"""
    
    payload = CreateStudentContextRequest(context="Test context")
    
    response = await client.post(
        "/api/v1/student-context",
        json=payload.model_dump()
    )
    
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_create_student_context_no_goal(authenticated_client, test_db, test_user):
    """Test that create student context returns 400 when user has no goal"""
    
    client, access_token = authenticated_client
    
    # Ensure user has no goal
    test_user.goal_id = None
    await test_db.commit()
    
    payload = CreateStudentContextRequest(context="Test context")
    
    response = await client.post(
        "/api/v1/student-context",
        json=payload.model_dump(),
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 400
    assert "active goal" in response.json()["detail"].lower()

@pytest.mark.asyncio
async def test_delete_student_context_successful(authenticated_client_with_objective, test_db, test_user):
    """Test that delete student context endpoint deletes the context"""
    
    client, access_token = authenticated_client_with_objective
    
    contexts = create_student_contexts(
        test_user.id,
        test_user.goal_id,
        test_user.current_objective_id,
        count=1
    )
    
    for context in contexts:
        test_db.add(context)
    await test_db.commit()
    await test_db.refresh(contexts[0])
    
    context_id = str(contexts[0].id)
    
    response = await client.delete(
        f"/api/v1/student-context/{context_id}",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 204
    
    # Verify it was deleted from the database
    query = select(StudentContext).where(StudentContext.id == uuid.UUID(context_id))
    result = await test_db.execute(query)
    deleted_context = result.scalars().first()
    
    assert deleted_context is None

@pytest.mark.asyncio
async def test_delete_student_context_unauthorized(client):
    """Test that delete student context endpoint returns 403 without token"""
    
    fake_id = str(uuid.uuid4())
    
    response = await client.delete(f"/api/v1/student-context/{fake_id}")
    
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_delete_student_context_not_found(authenticated_client_with_objective, test_user):
    """Test that delete student context endpoint returns 404 for non-existent context"""
    
    client, access_token = authenticated_client_with_objective
    
    fake_id = str(uuid.uuid4())
    
    response = await client.delete(
        f"/api/v1/student-context/{fake_id}",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 404
    assert "not found" in response.json()["detail"].lower()

@pytest.mark.asyncio
async def test_delete_student_context_forbidden(authenticated_client_with_objective, test_db, test_user):
    """Test that delete student context endpoint returns 403 for context owned by another student"""
    
    client, access_token = authenticated_client_with_objective
    
    # Create another student with a goal and objective
    other_student = Student(
        email="other@example.com",
        google_id="99999",
        name="Other User"
    )
    test_db.add(other_student)
    await test_db.flush()
    
    other_goal = Goal(
        student_id=other_student.id,
        name="Other Goal",
        description="Other Goal Description"
    )
    test_db.add(other_goal)
    await test_db.flush()
    
    other_objective = Objective(
        goal_id=other_goal.id,
        name="Other Objective",
        description="Other Objective Description",
        ai_model="test-model"
    )
    test_db.add(other_objective)
    await test_db.flush()
    
    # Create a context for the other student
    other_context = create_student_contexts(
        other_student.id,
        other_goal.id,
        other_objective.id,
        count=1
    )[0]
    test_db.add(other_context)
    await test_db.commit()
    await test_db.refresh(other_context)
    
    response = await client.delete(
        f"/api/v1/student-context/{other_context.id}",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 403
    assert "does not belong" in response.json()["detail"].lower()
