from datetime import date

from pydantic import BaseModel, Field


class RecentLesson(BaseModel):
    """A finished lesson on Home. `date` is the server's local date it was answered."""

    lesson_id: str
    date: date
    accuracy: float = Field(..., description="0..100")
    elo_delta: int
    duration_seconds: int


class EloPoint(BaseModel):
    """The goal's rating at the end of one day: that day's last lesson's `elo_after`."""

    date: date
    elo: int


class HomeDashboard(BaseModel):
    """GET /home: the active goal's dashboard."""

    goal_name: str
    current_elo: int
    current_streak: int = Field(..., description="User-wide, not per goal")
    recent_lessons: list[RecentLesson] = Field(..., description="Newest first, bounded")
    elo_history: list[EloPoint] = Field(
        ..., description="One point per day with a lesson, oldest first"
    )
