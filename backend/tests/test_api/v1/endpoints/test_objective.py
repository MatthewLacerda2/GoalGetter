import pytest
from backend.schemas.objective import ObjectiveResponse, ObjectiveListResponse
from backend.models.objective_note import ObjectiveNote as ObjectiveNoteModel

@pytest.mark.asyncio
async def test_get_objective_successful(auth_client, test_db, test_user):
    """Test getting an objective"""
    note = ObjectiveNoteModel(
        objective_id=test_user.current_objective_id,
        title="Test Note 1",
        info="First test note",
        ai_model="test-model"
    )
    test_db.add(note)
    await test_db.flush()    
    await test_db.commit()
    
    response = await auth_client.get("/api/v1/objective")
    objective_response = ObjectiveResponse.model_validate(response.json())
    
    assert response.status_code == 200
    assert len(objective_response.notes) > 0

@pytest.mark.asyncio
async def test_get_objective_list_successful(auth_client):
    """Test getting all user objectives"""
    response = await auth_client.get("/api/v1/objective/list")
    objectives_response = ObjectiveListResponse.model_validate(response.json())
    
    assert response.status_code == 200
    assert len(objectives_response.objective_list) > 0

@pytest.mark.asyncio
async def test_get_objective_unauthorized(client):
    """Test getting current objective without auth header returns 403"""
    response = await client.get("/api/v1/objective")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_get_objective_list_unauthorized(client):
    """Test getting objective list without auth header returns 403"""
    response = await client.get("/api/v1/objective/list")
    assert response.status_code == 403