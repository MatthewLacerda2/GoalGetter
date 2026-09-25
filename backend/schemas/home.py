from datetime import date

from pydantic import BaseModel, Field


class RecentLesson(BaseModel):
    """A lesson on Home: the answers that carry one `lesson_id`, counted
    together (#131). `date` is the app's calendar date they were given.

    There is no `elo_delta`: how the rating moves over a lesson has no stored
    history since the `lessons` table went, and gets one again with #62.
    """

    lesson_id: str
    date: date
    accuracy: float = Field(..., description="0..100")
    duration_seconds: int


class HomeDashboard(BaseModel):
    """GET /home: the active goal's dashboard."""

    goal_name: str
    current_elo: int
    current_streak: int = Field(..., description="User-wide, not per goal")
    recent_lessons: list[RecentLesson] = Field(..., description="Newest first, bounded")
