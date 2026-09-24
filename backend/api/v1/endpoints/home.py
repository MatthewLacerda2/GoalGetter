"""GET /home: the dashboard for the active goal (students.current_goal_id)."""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from backend.api.v1.goal_dependencies import get_active_goal
from backend.core.clock import app_date
from backend.core.database import get_db
from backend.models.goal import Goal
from backend.repositories.lesson_repository import LessonRepository
from backend.schemas.home import HomeDashboard, RecentLesson
from backend.services.lessons.elo_history import daily_elo_history
from backend.services.lessons.streak import student_streak

router = APIRouter()

# Home shows the first few (recent_lessons_list.dart: 4); a little headroom
# lets the app show more without an API change.
RECENT_LESSONS_LIMIT = 10


@router.get("", response_model=HomeDashboard)
async def get_home(goal: Goal = Depends(get_active_goal), db: AsyncSession = Depends(get_db)):
    """Rating, streak, recent lessons and the daily elo series. No active goal is 404."""
    lessons = LessonRepository(db)
    recent = await lessons.list_recent_finished_by_goal(goal.id, RECENT_LESSONS_LIMIT)
    return HomeDashboard(
        goal_name=goal.name,
        current_elo=goal.rating,
        current_streak=await student_streak(db, goal.student_id),
        recent_lessons=[
            RecentLesson(
                lesson_id=str(lesson.id),
                date=app_date(lesson.finished_at),
                accuracy=lesson.accuracy,
                elo_delta=lesson.elo_delta,
                duration_seconds=lesson.total_seconds,
            )
            for lesson in recent
        ],
        elo_history=daily_elo_history(await lessons.list_finished_by_goal(goal.id)),
    )
