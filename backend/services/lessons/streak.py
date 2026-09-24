"""The study streak: user-wide, computed from lesson activity, never stored.

The rule (#56): the run of consecutive days with at least one finished lesson
on any goal, counted back from today, or from yesterday when there is none
today yet. Days are the app's calendar days, in `core.clock.APP_TIMEZONE`, and
never the server's zone (#92) - which made a lesson finished at 22:00 Brasilia
count for the next day.
"""

from collections.abc import Iterable
from datetime import date, datetime, timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from backend.core.clock import app_date
from backend.core.clock import today as app_today
from backend.repositories.lesson_repository import LessonRepository


def current_streak(finished_at: Iterable[datetime], today: date) -> int:
    """How many consecutive days, ending today (or yesterday), had a finished lesson."""
    days = {app_date(moment) for moment in finished_at}
    day = today if today in days else today - timedelta(days=1)
    streak = 0
    while day in days:
        streak += 1
        day -= timedelta(days=1)
    return streak


async def student_streak(db: AsyncSession, student_id) -> int:
    """The signed-in student's streak as of today (the app's calendar date)."""
    finished_at = await LessonRepository(db).list_finished_at_by_student(student_id)
    return current_streak(finished_at, app_today())
