"""The streak: consecutive days on which the student answered something (#131)."""

from datetime import date, datetime, timedelta
from zoneinfo import ZoneInfo

import pytest

from backend.core import clock
from backend.services.lessons.streak import current_streak, student_streak
from backend.tests.fixtures.lessons import days_ago

TODAY = date(2026, 9, 21)


def on(days_before: int, hour: int = 12) -> datetime:
    """An aware moment `days_before` days before TODAY, on the app's wall clock."""
    return clock.app_moment(TODAY - timedelta(days=days_before), hour)


def test_no_answers_is_zero():
    assert current_streak([], TODAY) == 0


def test_an_answer_today_counts():
    assert current_streak([on(0)], TODAY) == 1


def test_counting_starts_yesterday_when_there_is_none_today_yet():
    assert current_streak([on(1), on(2)], TODAY) == 2


def test_only_the_day_before_yesterday_is_no_streak():
    assert current_streak([on(2)], TODAY) == 0


def test_a_gap_breaks_the_run():
    assert current_streak([on(0), on(1), on(3), on(4)], TODAY) == 2


def test_several_answers_on_one_day_count_once():
    assert current_streak([on(0, 9), on(0, 18), on(1)], TODAY) == 2


def test_an_answer_at_22_brasilia_counts_for_that_day():
    """#92: 22:00 in Sao Paulo is 01:00 UTC the next day. The day boundary is
    the app's, not the server's, so this answer belongs to the 21st."""
    answered = datetime(2026, 9, 21, 22, tzinfo=ZoneInfo("America/Sao_Paulo"))

    assert current_streak([answered], date(2026, 9, 21)) == 1


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
