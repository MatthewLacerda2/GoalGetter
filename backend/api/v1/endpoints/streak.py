from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from datetime import datetime, timedelta, date
from backend.core.database import get_db
from backend.models.student import Student
from backend.models.streak_day import StreakDay
from backend.schemas.streak import TimePeriodStreak, StreakDay as StreakDaySchema

router = APIRouter()

@router.get("/{student_id}/week", response_model=TimePeriodStreak)
async def get_week_streak(
    student_id: str,
    db: AsyncSession = Depends(get_db)
):
    """Get streak days for the current week for a specific student"""
    
    query = select(Student).where(Student.id == student_id)
    result = await db.execute(query)
    student = result.scalars().first()
    
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    today = datetime.now()    
    start_of_week = today - timedelta(days=today.weekday())
    start_of_week = start_of_week.replace(hour=0, minute=0, second=0, microsecond=0)    
    end_of_week = start_of_week + timedelta(days=6, hours=23, minutes=59, seconds=59)
    
    query = select(StreakDay).where(
        and_(
            StreakDay.student_id == student_id,
            StreakDay.date_time >= start_of_week,
            StreakDay.date_time <= end_of_week
        )
    )
    
    result = await db.execute(query)
    
    streak_days = result.scalars().all()    
    streak_day_schemas = [
        StreakDaySchema(
            id=day.id,
            date_time=day.date_time
        ) for day in streak_days
    ]
    
    return TimePeriodStreak(
        current_streak=student.current_streak,
        streak_days=streak_day_schemas
    )

@router.get("/{student_id}/month", response_model=TimePeriodStreak)
async def get_month_streak(
    student_id: str,
    target_date: date,
    db: AsyncSession = Depends(get_db)
):
    """Get streak days for a specific month for a specific student"""
    
    query = select(Student).where(Student.id == student_id)
    result = await db.execute(query)
    student = result.scalars().first()
    
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    start_of_month = date(target_date.year, target_date.month, 1)
    if target_date.month == 12:
        end_of_month = date(target_date.year + 1, 1, 1) - timedelta(microseconds=1)
    else:
        end_of_month = date(target_date.year, target_date.month + 1, 1) - timedelta(microseconds=1)
    
    query = select(StreakDay).where(
        and_(
            StreakDay.student_id == student_id,
            StreakDay.date_time >= start_of_month,
            StreakDay.date_time <= end_of_month
        )
    )
    
    result = await db.execute(query)
    
    streak_days = result.scalars().all()    
    streak_day_schemas = [
        StreakDaySchema(
            id=day.id,
            date_time=day.date_time
        ) for day in streak_days
    ]
    
    return TimePeriodStreak(
        current_streak=student.current_streak,
        streak_days=streak_day_schemas
    )