"""The study streak: user-wide, computed from lesson activity, never stored.

The rule (#56): the run of consecutive days with at least one finished lesson
on any goal, counted back from today, or from yesterday when there is none
today yet. Days are the server's local date; time zones can come later.
"""

from collections.abc import Iterable
from datetime import date, datetime, timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from backend.repositories.lesson_repository import LessonRepository


def local_date(moment: datetime) -> date:
    """The server's local calendar date of a stored timestamp."""
    return moment.astimezone().date()


def current_streak(finished_at: Iterable[datetime], today: date) -> int:
    """How many consecutive days, ending today (or yesterday), had a finished lesson."""
    days = {local_date(moment) for moment in finished_at}
    day = today if today in days else today - timedelta(days=1)
    streak = 0
    while day in days:
        streak += 1
        day -= timedelta(days=1)
    return streak


async def student_streak(db: AsyncSession, student_id) -> int:
    """The signed-in student's streak as of today (the server's local date)."""
    finished_at = await LessonRepository(db).list_finished_at_by_student(student_id)
    return current_streak(finished_at, date.today())
