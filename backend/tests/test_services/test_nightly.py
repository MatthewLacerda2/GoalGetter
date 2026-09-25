"""The nightly run and who it skips (#89).

Two halves. `decide` is pure, so the rule - who is skipped, who gets
resources - is pinned without a database or a clock. The rest drives the real
job against the test session with every Gemini call recorded, because the thing
worth proving about a skip is not the return value but that **nothing was
called**: a student who answered nothing costs nothing, not even a cheap call.
Since #131 the gate reads the answers themselves - there is no lesson row.

Every moment here is written in UTC and converted, never built in the ambient
zone - the same discipline as the clock's own tests (#92). 03:00 in
America/Sao_Paulo is 06:00 UTC.
"""

from datetime import UTC, datetime
from unittest.mock import patch

import pytest

from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.jobs.nightly import decide, run_for_student, run_nightly
from backend.tests.fixtures.jobs import NIGHTLY, chain_gemini, resource


def utc(*args) -> datetime:
    return datetime(*args, tzinfo=UTC)


THURSDAY_RUN = utc(2026, 9, 24, 6)  # 03:00 Brasilia, Thursday
WEDNESDAY_EVENING = utc(2026, 9, 23, 23)  # 20:00 Brasilia the evening before
LAST_WEEK = utc(2026, 9, 10, 12)
MONDAY_RUN = utc(2026, 9, 28, 6)  # 03:00 Brasilia, Monday
SUNDAY_EVENING = utc(2026, 9, 27, 23)  # 20:00 Brasilia the evening before


def test_a_student_who_never_answered_anything_is_skipped():
    assert decide(None, THURSDAY_RUN).run is False


def test_a_student_whose_last_answer_is_older_than_the_night_is_skipped():
    assert decide(LAST_WEEK, THURSDAY_RUN).run is False


def test_the_evening_before_counts_as_today():
    """The run fires at 03:00: a calendar day would skip everyone who studied"""
    decision = decide(WEDNESDAY_EVENING, THURSDAY_RUN)

    assert (decision.run, decision.with_resources) == (True, False)


def test_an_answer_given_in_the_small_hours_still_counts():
    """01:00 Brasilia is the same study day as the evening that led to it"""
    assert decide(utc(2026, 9, 24, 4), THURSDAY_RUN).run is True


def test_the_day_before_the_last_run_is_over_however_recent_it_felt():
    """03:00 Brasilia is the boundary: a minute earlier belongs to the run before"""
    assert decide(utc(2026, 9, 23, 5, 59), THURSDAY_RUN).run is False


def test_resources_are_asked_for_on_mondays():
    decision = decide(SUNDAY_EVENING, MONDAY_RUN)

    assert (decision.run, decision.with_resources) == (True, True)


@pytest.mark.asyncio
async def test_a_student_who_did_nothing_costs_no_gemini_call(
    test_db, test_user, goal_factory, lesson_factory
):
    """The skip is the point: not a cheaper run, no run"""
    goal = await goal_factory(test_user)
    await lesson_factory(goal, LAST_WEEK)
    await test_db.commit()

    calls = []
    with chain_gemini(test_db, calls):
        assert await run_nightly(THURSDAY_RUN) == (1, 0)

    assert calls == []
    assert await StudentContextRepository(test_db).list_valid(test_user.id) == []


@pytest.mark.asyncio
async def test_a_student_who_answered_something_gets_context_then_questions(
    test_db, test_user, goal_factory, lesson_factory
):
    """Six nights a week the chain stops after the second step"""
    goal = await goal_factory(test_user)
    await lesson_factory(goal, WEDNESDAY_EVENING)
    await test_db.commit()

    calls = []
    with chain_gemini(test_db, calls, found=[resource(goal.id, "https://good.dev/a")]):
        assert await run_nightly(THURSDAY_RUN) == (1, 1)

    assert [name for name, _ in calls] == ["context", "questions"]


@pytest.mark.asyncio
async def test_resources_are_searched_on_monday_and_only_then(
    test_db, test_user, goal_factory, lesson_factory
):
    """The same student, the same lesson, one night later in the week"""
    goal = await goal_factory(test_user)
    await lesson_factory(goal, SUNDAY_EVENING)
    await test_db.commit()

    calls = []
    with chain_gemini(test_db, calls, found=[resource(goal.id, "https://good.dev/a")]):
        assert await run_nightly(MONDAY_RUN) == (1, 1)

    assert [name for name, _ in calls] == ["context", "questions", "resources"]


@pytest.mark.asyncio
async def test_a_chat_is_not_activity(
    test_db, test_user, goal_factory, exchange_factory, lesson_factory
):
    """'Chat activity does not count for this; only lessons' (the user)"""
    goal = await goal_factory(test_user)
    await exchange_factory(goal)
    await test_db.commit()

    calls = []
    with chain_gemini(test_db, calls):
        assert await run_nightly(THURSDAY_RUN) == (1, 0)

    assert calls == []


@pytest.mark.asyncio
async def test_one_student_failing_does_not_stop_the_next(
    test_db, student_factory, goal_factory, lesson_factory
):
    """Where the chain's re-raise is caught: a quota error is one student's night"""
    first = await student_factory(email="a@b.c", google_id="a")
    second = await student_factory(email="d@e.f", google_id="d")
    for student in (first, second):
        goal = await goal_factory(student)
        await lesson_factory(goal, WEDNESDAY_EVENING)
    await test_db.commit()

    seen = []

    async def chain(student_id, with_resources=True):
        seen.append(student_id)
        if student_id == str(first.id):
            raise RuntimeError("quota")

    with patch(NIGHTLY + ".run_student_chain", chain), chain_gemini(test_db, []):
        assert await run_nightly(THURSDAY_RUN) == (2, 1)

    assert seen == [str(first.id), str(second.id)]


@pytest.mark.asyncio
async def test_running_it_by_hand_logs_the_decision_it_took(
    test_db, test_user, goal_factory, lesson_factory, caplog
):
    """'It must be runnable by hand for one student' - and say what it decided"""
    goal = await goal_factory(test_user)
    await lesson_factory(goal, LAST_WEEK)
    await test_db.commit()

    calls = []
    with chain_gemini(test_db, calls), caplog.at_level("INFO"):
        assert await run_for_student(str(test_user.id), THURSDAY_RUN) is False

    assert "skipped: last answer 2026-09-10 12:00Z is before 06:00Z" in caplog.text
