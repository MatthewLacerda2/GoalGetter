import pytest
from backend.schemas.objective import ObjectiveResponse
import logging
from backend.models.objective import Objective
from backend.models.objective_note import ObjectiveNote as ObjectiveNoteModel

logger = logging.getLogger(__name__)

@pytest.mark.asyncio
async def test_get_objective(client, mock_google_verify, test_db, test_user):
    """Test getting an objective"""
    
    objective = Objective(
        goal_id=test_user.goal_id,
        name="Test Objective",
        description="A test objective for testing purposes",
        percentage_completed=0.5,
    )
    test_db.add(objective)
    await test_db.flush()
    
    note = ObjectiveNoteModel(
        objective_id=objective.id,
        title="Test Note 1",
        description="First test note",
    )
    test_db.add(note)
    await test_db.flush()    
    await test_db.commit()
    await test_db.refresh(objective)
    
    login_response = await client.post(
        "/api/v1/auth/login",
        json={"access_token": "fixture_user_token"}
    )
    access_token = login_response.json()["access_token"]
    
    response = await client.get(
        "/api/v1/objective",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    objective_response = ObjectiveResponse.model_validate(response.json())
    
    assert response.status_code == 200
    assert isinstance(objective_response, ObjectiveResponse)
    assert len(objective_response.notes) == 1