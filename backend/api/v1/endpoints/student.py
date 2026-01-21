import logging
from fastapi import APIRouter
from fastapi import Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from backend.core.database import get_db
from backend.core.security import get_current_user
from backend.models.student import Student
from backend.schemas.student import StudentCurrentStatusResponse

logger = logging.getLogger(__name__)

router = APIRouter()

@router.get("", response_model=StudentCurrentStatusResponse, status_code=status.HTTP_200_OK)
async def get_student_current_status(
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """Get the current status of the student"""

    return StudentCurrentStatusResponse(
        student_id=str(current_user.id),
        student_name=current_user.name,
        student_email=current_user.email,
        current_streak=current_user.current_streak,
        overall_xp=current_user.overall_xp,
        goal_id=str(current_user.goal_id) if current_user.goal_id else None,
        goal_name=current_user.goal_name or None,
    )