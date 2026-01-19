import pytest
from backend.schemas.student import StudentCurrentStatusResponse

@pytest.mark.asyncio
async def test_get_student_current_status_successful(authenticated_client_with_objective, test_user):
    """Test getting the current status of the student"""
    
    client, access_token = authenticated_client_with_objective
    
    response = await client.get(
        "/api/v1/student",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    student_current_status_response = StudentCurrentStatusResponse.model_validate(response.json())
    
    assert response.status_code == 200
    assert isinstance(student_current_status_response, StudentCurrentStatusResponse)
    
    assert student_current_status_response.student_id == str(test_user.id)
    assert student_current_status_response.goal_id == str(test_user.goal_id) if test_user.goal_id else None

@pytest.mark.asyncio
async def test_get_student_current_status_unauthorized(client):
    """Test getting the current status of the student unauthorized"""
    
    response = await client.get("/api/v1/student")
    assert response.status_code == 403
    
@pytest.mark.asyncio
async def test_get_student_current_status_invalid_token(client):
    """Test getting the current status of the student invalid token"""
    
    response = await client.get("/api/v1/student", headers={"Authorization": "Bearer invalid_token"})
    assert response.status_code == 401