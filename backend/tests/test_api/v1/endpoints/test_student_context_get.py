import pytest
from backend.schemas.student_context import StudentContextResponse, StudentContextItem

@pytest.mark.asyncio
async def test_get_student_contexts_successful(auth_client, test_db, test_user, student_context_factory):
    """Test that get student contexts endpoint returns a valid response"""
    await student_context_factory(
        test_user.id,
        test_user.goal_id,
        test_user.current_objective_id,
        count=3
    )
    await test_db.commit()
    
    response = await auth_client.get("/api/v1/student-context")
    assert response.status_code == 200
    context_response = StudentContextResponse.model_validate(response.json())
    assert len(context_response.contexts) == 3
    assert all(isinstance(c, StudentContextItem) for c in context_response.contexts)

@pytest.mark.asyncio
async def test_get_student_contexts_unauthorized(client):
    """Test that get student contexts endpoint returns 403 without token"""
    response = await client.get("/api/v1/student-context")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_get_student_contexts_no_objective(auth_client, test_db, test_user):
    """Test that get student contexts returns empty list when user has no objective"""
    test_user.current_objective_id = None
    await test_db.commit()
    
    response = await auth_client.get("/api/v1/student-context")
    assert response.status_code == 200
    context_response = StudentContextResponse.model_validate(response.json())
    assert len(context_response.contexts) == 0
