"""The streak: days studied, two missed days a week forgiven (#131, #204).

The rule is arithmetic, so it is pinned as a table: a calendar and the streak
it gives. A calendar is one group per calendar week, Monday to Sunday, the last
group ending on TODAY (a Thursday): `x` is a day he answered something, `.` a
day he did not. Leading dots are days before his first answer.
"""

from datetime import date, datetime, timedelta
from zoneinfo import ZoneInfo

import pytest

from backend.core import clock
from backend.services.lessons.streak import current_streak, student_streak
from backend.tests.fixtures.lessons import days_ago

TODAY = date(2026, 9, 24)  # a Thursday


def on(days_before: int, hour: int = 12) -> datetime:
    """An aware moment `days_before` days before TODAY, on the app's wall clock."""
    return clock.app_moment(TODAY - timedelta(days=days_before), hour)


def studied(calendar: str) -> list[datetime]:
    """One answer at noon on each `x` of `calendar`, its last mark on TODAY."""
    *weeks, this_week = calendar.split(" ")
    assert len(this_week) == TODAY.weekday() + 1, "the last group is Monday to TODAY"
    assert all(len(week) == 7 for week in weeks), "every earlier group is a whole week"
    marks = "".join(weeks) + this_week
    return [on(len(marks) - 1 - i) for i, mark in enumerate(marks) if mark == "x"]


CALENDARS = [
    # (calendar, streak, what it pins)
    ("....", 0, "no answers"),
    ("...x", 1, "an answer today counts"),
    ("..x.", 1, "today is not missed until it ends"),
    ("xxxxxxx xxxx", 11, "every day studied"),
    ("xxxxxxx x.x.", 9, "one missed day keeps the streak"),
    ("xxxxxxx .x.x", 9, "two missed days keep it, and do not add to it"),
    ("xxxxxxx ...x", 1, "the third missed day resets it"),
    ("xxxxxxx ..x.", 8, "two misses and today pending: still kept"),
    ("xxxxxxx ..x.xxx xxxx", 7, "the third miss resets even after a studied day between"),
    ("xxxxx.. ..xx", 7, "week boundary: two misses each side of Monday keep it"),
    ("xxxx... .xxx", 3, "week boundary: three misses by Sunday reset it"),
    ("xxxxxxx ...xx.x xxxx", 5, "a reset does not refill the week: the fourth miss resets again"),
    ("...x.x. xxxx", 6, "days before his first answer are not missed days"),
]


@pytest.mark.parametrize(("calendar", "streak", "pins"), CALENDARS)
def test_the_streak_of_a_calendar(calendar, streak, pins):
    assert current_streak(studied(calendar), TODAY) == streak, pins


def test_several_answers_on_one_day_count_once():
    assert current_streak([on(0, 9), on(0, 18), on(1)], TODAY) == 2


def test_an_answer_at_22_brasilia_counts_for_that_day():
    """#92: 22:00 in Sao Paulo is 01:00 UTC the next day. The day boundary is
    the app's, not the server's, so this answer belongs to the 24th."""
    answered = datetime(2026, 9, 24, 22, tzinfo=ZoneInfo("America/Sao_Paulo"))

    assert current_streak([answered], TODAY) == 1


@pytest.mark.asyncio
async def test_one_answer_is_enough_to_make_a_day_count(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """A day counts because he answered a question, not because a lesson closed"""
    goal = await goal_factory(test_user)
    await answer_factory(await question_factory(goal), correct=False, answered_at=days_ago(0))

    assert await student_streak(test_db, test_user.id) == 1


@pytest.mark.asyncio
async def test_the_day_boundary_is_the_students_midnight_not_the_servers(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """23:00 Brasilia yesterday and 01:00 Brasilia today are two days, not one.

    Both moments land on the same UTC date, so a streak read off the server's
    calendar would call this a single day and answer 1.
    """
    goal = await goal_factory(test_user)
    yesterday = clock.today() - timedelta(days=1)
    for moment in (clock.app_moment(yesterday, 23), clock.app_moment(clock.today(), 1)):
        await answer_factory(await question_factory(goal), correct=True, answered_at=moment)

    assert await student_streak(test_db, test_user.id) == 2
