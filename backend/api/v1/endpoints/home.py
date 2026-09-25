"""GET /home: the dashboard for the active goal (students.current_goal_id)."""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from backend.api.v1.goal_dependencies import get_active_goal
from backend.core.clock import app_date
from backend.core.database import get_db
from backend.models.goal import Goal
from backend.repositories.student_answer_repository import StudentAnswerRepository
from backend.schemas.home import HomeDashboard, RecentLesson
from backend.services.lessons.streak import student_streak

router = APIRouter()

# Home shows the first few (recent_lessons_list.dart: 4); a little headroom
# lets the app show more without an API change.
RECENT_LESSONS_LIMIT = 10


@router.get("", response_model=HomeDashboard)
async def get_home(goal: Goal = Depends(get_active_goal), db: AsyncSession = Depends(get_db)):
    """Rating, streak and recent lessons. No active goal is 404.

    A lesson here is a group of answers sharing one `lesson_id` (#131); the
    elo series it used to carry is gone with the `lessons` table and returns
    with #62.
    """
    recent = await StudentAnswerRepository(db).list_recent_lessons_by_goal(
        goal.id, RECENT_LESSONS_LIMIT
    )
    return HomeDashboard(
        goal_name=goal.name,
        current_elo=goal.rating,
        current_streak=await student_streak(db, goal.student_id),
        recent_lessons=[
            RecentLesson(
                lesson_id=lesson.lesson_id,
                date=app_date(lesson.answered_at),
                accuracy=lesson.accuracy,
                duration_seconds=lesson.total_seconds,
            )
            for lesson in recent
        ],
    )
