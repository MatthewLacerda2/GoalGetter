from datetime import date, datetime, timedelta
from zoneinfo import ZoneInfo

from backend.services.lessons.streak import current_streak

TODAY = date(2026, 9, 21)


def on(days_before: int, hour: int = 12) -> datetime:
    """A local, aware moment `days_before` days before TODAY."""
    day = TODAY - timedelta(days=days_before)
    return datetime(day.year, day.month, day.day, hour).astimezone()


def test_no_lessons_is_zero():
    assert current_streak([], TODAY) == 0


def test_a_lesson_today_counts():
    assert current_streak([on(0)], TODAY) == 1


def test_counting_starts_yesterday_when_there_is_none_today_yet():
    assert current_streak([on(1), on(2)], TODAY) == 2


def test_only_the_day_before_yesterday_is_no_streak():
    assert current_streak([on(2)], TODAY) == 0


def test_a_gap_breaks_the_run():
    assert current_streak([on(0), on(1), on(3), on(4)], TODAY) == 2


def test_several_lessons_on_one_day_count_once():
    assert current_streak([on(0, 9), on(0, 18), on(1)], TODAY) == 2


def test_a_lesson_at_22_brasilia_counts_for_that_day():
    """#92: 22:00 in Sao Paulo is 01:00 UTC the next day. The day boundary is
    the app's, not the server's, so this lesson belongs to the 21st."""
    finished = datetime(2026, 9, 21, 22, tzinfo=ZoneInfo("America/Sao_Paulo"))

    assert current_streak([finished], date(2026, 9, 21)) == 1
