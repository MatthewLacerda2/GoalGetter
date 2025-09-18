import pytest
from backend.schemas.objective import ObjectiveResponse
import logging
from backend.models.objective import Objective
from backend.models.objective_note import ObjectiveNote as ObjectiveNoteModel

logger = logging.getLogger(__name__)

@pytest.mark.asyncio
async def test_get_objective_successful(authenticated_client_with_objective, test_db):
    """Test getting an objective"""
    
    client, access_token = authenticated_client_with_objective
    
    from sqlalchemy import select
    stmt = select(Objective)
    result = await test_db.execute(stmt)
    objective = result.scalar_one()
    
    note = ObjectiveNoteModel(
        objective_id=objective.id,
        title="Test Note 1",
        info="First test note",
    )
    test_db.add(note)
    await test_db.flush()    
    await test_db.commit()
    await test_db.refresh(objective)
    
    response = await client.get(
        "/api/v1/objective",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    objective_response = ObjectiveResponse.model_validate(response.json())
    
    assert response.status_code == 200
    assert isinstance(objective_response, ObjectiveResponse)
    assert len(objective_response.notes) == 1