from datetime import datetime

from backend.models.lesson import Lesson
from backend.services.lessons.elo_history import daily_elo_history


def lesson(day: int, hour: int, elo_after: int) -> Lesson:
    return Lesson(finished_at=datetime(2026, 9, day, hour).astimezone(), elo_after=elo_after)


def test_one_point_per_day_with_that_days_last_rating_oldest_first():
    lessons = [lesson(1, 9, 1205), lesson(1, 18, 1210), lesson(3, 12, 1190)]

    points = daily_elo_history(lessons)

    assert [(p.date.isoformat(), p.elo) for p in points] == [
        ("2026-09-01", 1210), ("2026-09-03", 1190),
    ]


def test_no_lessons_is_an_empty_history():
    assert daily_elo_history([]) == []
