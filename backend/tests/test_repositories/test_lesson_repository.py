import pytest

from backend.repositories.lesson_repository import LessonRepository
from backend.tests.fixtures.lessons import days_ago


@pytest.mark.asyncio
async def test_recent_finished_is_newest_first_bounded_and_finished_only(
    test_db, test_user, goal_factory, finished_lesson_factory
):
    goal = await goal_factory(test_user)
    for days in (3, 1, 2):
        await finished_lesson_factory(goal, days_ago(days), elo_after=1000 + days)
    await finished_lesson_factory(goal, None)

    recent = await LessonRepository(test_db).list_recent_finished_by_goal(goal.id, limit=2)

    assert [lesson.elo_after for lesson in recent] == [1001, 1002]


@pytest.mark.asyncio
async def test_finished_by_goal_is_oldest_first_and_only_that_goal(
    test_db, test_user, goal_factory, finished_lesson_factory
):
    goal = await goal_factory(test_user)
    other = await goal_factory(test_user, name="Chess")
    await finished_lesson_factory(goal, days_ago(1), elo_after=2)
    await finished_lesson_factory(goal, days_ago(2), elo_after=1)
    await finished_lesson_factory(other, days_ago(1), elo_after=99)
    await finished_lesson_factory(goal, None)

    lessons = await LessonRepository(test_db).list_finished_by_goal(goal.id)

    assert [lesson.elo_after for lesson in lessons] == [1, 2]


@pytest.mark.asyncio
async def test_finished_at_by_student_spans_goals_and_skips_others_and_unfinished(
    test_db, test_user, student_factory, goal_factory, finished_lesson_factory
):
    italian = await goal_factory(test_user)
    chess = await goal_factory(test_user, name="Chess")
    theirs = await goal_factory(await student_factory(email="o@example.com", google_id="o"))
    await finished_lesson_factory(italian, days_ago(2))
    await finished_lesson_factory(chess, days_ago(1))
    await finished_lesson_factory(theirs, days_ago(0))
    await finished_lesson_factory(italian, None)

    moments = await LessonRepository(test_db).list_finished_at_by_student(test_user.id)

    assert moments == [days_ago(1), days_ago(2)]
