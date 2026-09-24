"""GET /me: the signed-in student's profile and streak (the Profile header)."""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from backend.core.database import get_db
from backend.core.security import get_current_user
from backend.models.student import Student
from backend.schemas.me import UserProfile
from backend.services.lessons.streak import student_streak

router = APIRouter()


@router.get("", response_model=UserProfile)
async def get_me(current_user: Student = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    return UserProfile(
        id=str(current_user.id),
        name=current_user.name,
        email=current_user.email,
        member_since=current_user.created_at,
        current_streak=await student_streak(db, current_user.id),
    )
