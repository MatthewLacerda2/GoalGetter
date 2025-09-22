import logging
from fastapi import APIRouter
from fastapi import HTTPException
from fastapi import Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from backend.core.database import get_db
from backend.core.security import get_current_user
from backend.schemas.objective import ObjectiveResponse
from backend.models.student import Student
from backend.repositories.objective_repository import ObjectiveRepository
from backend.repositories.objective_note_repository import ObjectiveNoteRepository

logger = logging.getLogger(__name__)

router = APIRouter()

@router.get("", response_model=ObjectiveResponse, status_code=status.HTTP_200_OK)
async def get_objective(
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """
    Get the latest objective for the current user
    """
    objective_repo = ObjectiveRepository(db)
    objective = await objective_repo.get_latest_by_goal_id(current_user.goal_id)
    
    if not objective:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Objective not found")
    
    objective_note_repo = ObjectiveNoteRepository(db)
    notes = await objective_note_repo.get_by_objective_id(objective.id)
    
    return ObjectiveResponse(
        id=objective.id,
        name=objective.name,
        description=objective.description,
        percentage_completed=objective.percentage_completed,
        created_at=objective.created_at,
        last_updated_at=objective.last_updated_at,
        notes=notes
    )