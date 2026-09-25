"""The study streak: user-wide, computed from answers, never stored.

The rule (#56, restated for #131): the run of consecutive days on which the
student **answered at least one question**, on any goal, counted back from
today, or from yesterday when there is none today yet. A day counts because he
answered something in it - there is no lesson row to have finished. Days are
the app's calendar days, in `core.clock.APP_TIMEZONE`, and never the server's
zone (#92) - which made an answer given at 22:00 Brasilia count for the next
day.
"""

from collections.abc import Iterable
from datetime import date, datetime, timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from backend.core.clock import app_date
from backend.core.clock import today as app_today
from backend.repositories.student_answer_repository import StudentAnswerRepository


def current_streak(answered_at: Iterable[datetime], today: date) -> int:
    """How many consecutive days, ending today (or yesterday), had an answer."""
    days = {app_date(moment) for moment in answered_at}
    day = today if today in days else today - timedelta(days=1)
    streak = 0
    while day in days:
        streak += 1
        day -= timedelta(days=1)
    return streak


async def student_streak(db: AsyncSession, student_id) -> int:
    """The signed-in student's streak as of today (the app's calendar date)."""
    answered_at = await StudentAnswerRepository(db).list_answered_at_by_student(student_id)
    return current_streak(answered_at, app_today())
