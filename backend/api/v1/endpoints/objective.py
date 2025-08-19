from fastapi import APIRouter
from backend.schemas.objective import ObjectiveResponse
from backend.core.database import get_db
from backend.core.security import get_current_user
from backend.models.student import Student
from backend.models.objective import Objective
from backend.models.objective_note import ObjectiveNote
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import Depends, status
from sqlalchemy import select
from fastapi import HTTPException
import logging

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
    stmt = select(Objective).where(Objective.goal_id == current_user.goal_id).order_by(Objective.last_updated_at.desc())
    result = await db.execute(stmt)
    objective = result.scalar_one_or_none()
    
    if not objective:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Objective not found")
    
    stmt = select(ObjectiveNote).where(ObjectiveNote.objective_id == objective.id)
    result = await db.execute(stmt)
    notes = result.scalars().all()
    
    from backend.schemas.objective import ObjectiveNote as ObjectiveNoteSchema
    note_schemas = [
        ObjectiveNoteSchema(
            id=note.id,
            title=note.title,
            description=note.description,
            created_at=note.created_at
        ) for note in notes
    ]
    
    return ObjectiveResponse(
        id=objective.id,
        name=objective.name,
        description=objective.description,
        percentage_completed=objective.percentage_completed,
        created_at=objective.created_at,
        last_updated_at=objective.last_updated_at,
        notes=note_schemas
    )