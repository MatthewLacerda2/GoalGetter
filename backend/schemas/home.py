from datetime import date
from uuid import UUID

from pydantic import BaseModel, Field


class RecentLesson(BaseModel):
    """A lesson on Home: the answers that carry one `lesson_id`, counted
    together. `date` is the app's calendar date they were given.

    There is no `elo_delta`: nothing stores how the rating moved over one
    lesson.
    """

    lesson_id: UUID
    date: date
    accuracy: float = Field(..., description="0..100")
    duration_seconds: int


class HomeDashboard(BaseModel):
    """GET /home: the active goal's dashboard."""

    goal_name: str
    current_elo: int
    current_streak: int = Field(..., description="User-wide, not per goal")
    recent_lessons: list[RecentLesson] = Field(..., description="Newest first, bounded")
