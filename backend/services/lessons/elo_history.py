"""Home's elo chart: one point per day that had a finished lesson.

The day is the app's calendar day (`core.clock`), not the server's (#92).
"""

from backend.core.clock import app_date
from backend.models.lesson import Lesson
from backend.schemas.home import EloPoint


def daily_elo_history(finished_oldest_first: list[Lesson]) -> list[EloPoint]:
    """Each day's last `elo_after`, oldest day first.

    Expects the lessons oldest first, as LessonRepository.list_finished_by_goal
    returns them, so a later lesson of the same day overwrites an earlier one.
    """
    by_day: dict = {}
    for lesson in finished_oldest_first:
        by_day[app_date(lesson.finished_at)] = lesson.elo_after
    return [EloPoint(date=day, elo=elo) for day, elo in by_day.items()]
