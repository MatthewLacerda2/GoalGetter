"""Home's elo chart: one point per day that had a finished lesson."""

from backend.models.lesson import Lesson
from backend.schemas.home import EloPoint
from backend.services.lessons.streak import local_date


def daily_elo_history(finished_oldest_first: list[Lesson]) -> list[EloPoint]:
    """Each day's last `elo_after`, oldest day first.

    Expects the lessons oldest first, as LessonRepository.list_finished_by_goal
    returns them, so a later lesson of the same day overwrites an earlier one.
    """
    by_day: dict = {}
    for lesson in finished_oldest_first:
        by_day[local_date(lesson.finished_at)] = lesson.elo_after
    return [EloPoint(date=day, elo=elo) for day, elo in by_day.items()]
