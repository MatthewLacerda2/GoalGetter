from fastapi import APIRouter, HTTPException, Depends
from typing import List
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from backend.core.database import get_db
from backend.models.student import Student
from backend.core.security import get_current_user
from backend.models.achievement import Achievement
from backend.models.player_achievement import PlayerAchievement
from backend.repositories.student_repository import StudentRepository
from backend.schemas.player_achievements import PlayerAchievementResponse, PlayerAchievementItem, LeaderboardResponse, LeaderboardItem

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

#TODO: change it to xp 'this week'
@router.get("/leaderboard", response_model=LeaderboardResponse)
async def get_leaderboard(
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """Get the leaderboard around the current user's XP level"""
    
    student_repo = StudentRepository(db)
    
    current_user_with_goal, leaderboard_users = await student_repo.get_leaderboard_around_user(
        current_user.id, 
        limit=10
    )
    
    if not current_user_with_goal:
        raise HTTPException(status_code=404, detail="User did not finish the onboarding and does not have an objective.")
    
    leaderboard_items: List[LeaderboardItem] = []
    for student in leaderboard_users:
        objective_name = student.goal.name  #TODO: query for the user's objective
        leaderboard_items.append(LeaderboardItem(
            name=student.name,
            objective=objective_name,
            xp=student.overall_xp
        ))
    
    return LeaderboardResponse(students=leaderboard_items)

#TODO: we'll need the XP for the last 30 days