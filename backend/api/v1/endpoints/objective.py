import logging
from fastapi import APIRouter
from fastapi import Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from backend.core.database import get_db
from backend.core.security import get_current_user
from backend.schemas.objective import ObjectiveResponse, ObjectiveListResponse, ObjectiveItem, ObjectiveNote
from backend.models.student import Student
from backend.repositories.objective_repository import ObjectiveRepository

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
    objective = await objective_repo.get_latest_by_goal_id_with_notes(current_user.goal_id)
    
    # Convert notes from SQLAlchemy objects to Pydantic models with string IDs
    notes = [
        ObjectiveNote(
            id=str(note.id),
            title=note.title,
            info=note.info,
            is_favorited=note.is_favorited,
            created_at=note.created_at
        )
        for note in objective.notes
    ]
    
    return ObjectiveResponse(
        id=str(objective.id),
        name=objective.name,
        description=objective.description,
        percentage_completed=objective.percentage_completed,
        created_at=objective.created_at,
        last_updated_at=objective.last_updated_at,
        notes=notes
    )

@router.get("/list", response_model=ObjectiveListResponse, status_code=status.HTTP_200_OK)
async def get_objectives_list(
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """
    Get all objectives for the current user's goal
    """
    objective_repo = ObjectiveRepository(db)
    objectives = await objective_repo.get_by_goal_id(current_user.goal_id)
    
    objective_items = [
        ObjectiveItem(
            id=str(obj.id),
            name=obj.name,
            description=obj.description,
            percentage_completed=int(obj.percentage_completed),
            created_at=obj.created_at,
            last_updated_at=obj.last_updated_at
        )
        for obj in objectives
    ]
    
    return ObjectiveListResponse(objective_list=objective_items)