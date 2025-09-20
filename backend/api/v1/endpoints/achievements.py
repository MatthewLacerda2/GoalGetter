from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from backend.core.database import get_db
from backend.models.student import Student
from backend.core.security import get_current_user
from backend.models.achievement import Achievement
from backend.models.player_achievement import PlayerAchievement
from backend.schemas.player_achievements import PlayerAchievementResponse, PlayerAchievementItem, LeaderboardResponse

router = APIRouter()

@router.get("/{student_id}", response_model=PlayerAchievementResponse)
async def get_achievements(
    student_id: str,
    db: AsyncSession = Depends(get_db)
):
    """Get achievements for a specific student"""
    
    query = select(Student).where(Student.id == student_id)
    result = await db.execute(query)
    student = result.scalars().first()
    
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    query = select(PlayerAchievement).where(PlayerAchievement.student_id == student_id)
    result = await db.execute(query)
    player_achievements = result.scalars().all()
    
    achievements = []
    for player_achievement in player_achievements:
        achievement_query = select(Achievement).where(Achievement.id == player_achievement.achievement_id)
        achievement_result = await db.execute(achievement_query)
        achievement = achievement_result.scalars().first()
    
        achievements.append(PlayerAchievementItem(
            id=player_achievement.id,
            name=achievement.name,
            description=achievement.description,
            image_url=achievement.image_url,
            achieved_at=player_achievement.achieved_at
        ))

    achievements.sort(key=lambda x: x.achieved_at, reverse=True)

    return PlayerAchievementResponse(achievements=achievements)

@router.get("/leaderboard", response_model=LeaderboardResponse)
async def get_leaderboard(
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """Get the leaderboard for the week"""
    
    pass

#TODO: we'll need the XP for the last 30 days