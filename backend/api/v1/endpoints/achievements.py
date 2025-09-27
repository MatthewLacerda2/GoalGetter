from typing import List
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import APIRouter, HTTPException, Depends, Query
from backend.core.database import get_db
from backend.core.security import get_current_user
from backend.schemas.streak import XpDay, XpByDaysResponse
from backend.models.student import Student
from backend.models.achievement import Achievement
from backend.repositories.student_repository import StudentRepository
from backend.repositories.streak_day_repository import StreakDayRepository
from backend.repositories.player_achievement_repository import PlayerAchievementRepository
from backend.schemas.player_achievement import PlayerAchievementResponse, PlayerAchievementItem, LeaderboardResponse, LeaderboardItem

router = APIRouter()

@router.get("/leaderboard", response_model=LeaderboardResponse)
async def get_leaderboard(
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """Get the leaderboard around the current user's XP level"""
    
    student_repo = StudentRepository(db)
    leaderboard_users = await student_repo.get_leaderboard_around_user(current_user.id, limit=10)
    
    leaderboard_items: List[LeaderboardItem] = []
    for student in leaderboard_users:
        objective_name = student.current_objective.name
        leaderboard_items.append(LeaderboardItem(
            name=student.name,
            objective=objective_name,
            xp=student.overall_xp
        ))
    
    return LeaderboardResponse(students=leaderboard_items)

@router.get("/xp_by_days", response_model=XpByDaysResponse)
async def get_xp_by_days(
    days: int = Query(30, ge=1, le=365, description="Number of days to look back"),
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """Get XP data for the current user over the last X days"""
    
    streak_repo = StreakDayRepository(db)
    streak_days = await streak_repo.get_by_student_id_and_days(current_user.id, days)
    
    xp_days = [XpDay.model_validate(streak_day) for streak_day in streak_days]
        
    return XpByDaysResponse(days=xp_days)

@router.get("/{student_id}", response_model=PlayerAchievementResponse)
async def get_achievements(
    student_id: str,
    limit: int = Query(None, ge=1, description="Limit number of achievements returned"),
    db: AsyncSession = Depends(get_db)
):
    """Get achievements for a specific student"""
    
    student_repo = StudentRepository(db)
    student = await student_repo.get_by_id(student_id)
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    player_achievements_repo = PlayerAchievementRepository(db)
    player_achievements = await player_achievements_repo.get_by_student_id(student_id, limit)
    
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