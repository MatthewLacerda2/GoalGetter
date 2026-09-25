"""Reading the answer history: the table a lesson became (#131)."""

from datetime import timedelta

import pytest

from backend.core import clock
from backend.repositories.student_answer_repository import StudentAnswerRepository
from backend.tests.fixtures.lessons import at, days_ago


@pytest.mark.asyncio
async def test_the_same_question_on_three_days_is_three_rows_read_back_in_order(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """'wrong on day one, right on day two, wrong again later' - the whole point"""
    goal = await goal_factory(test_user)
    question = await question_factory(goal, "What is 'ciao'?", correct=1)
    for days, correct in ((4, False), (3, True), (1, False)):
        await answer_factory(question, correct=correct, answered_at=days_ago(days))

    history = await StudentAnswerRepository(test_db).list_for_question(question.id)

    assert [clock.app_date(a.created_at) for a in history] == [
        clock.today() - timedelta(days=days) for days in (4, 3, 1)
    ]
    assert [a.selected_index == question.right_answer_index for a in history] == [
        False,
        True,
        False,
    ]
    assert len({a.lesson_id for a in history}) == 3


@pytest.mark.asyncio
async def test_a_lesson_is_the_answers_that_share_its_mark_in_the_order_asked(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    mine = await goal_factory(test_user)
    first = await question_factory(mine, "first")
    second = await question_factory(mine, "second")
    elsewhere = await question_factory(mine, "another lesson")
    mark = (await answer_factory(second, True, at(1), position=1)).lesson_id
    await answer_factory(first, True, at(0), lesson_id=mark, position=0)
    await answer_factory(elsewhere, True, at(2))

    batch = await StudentAnswerRepository(test_db).list_by_lesson(mark)

    assert [a.question_id for a in batch] == [first.id, second.id]


@pytest.mark.asyncio
async def test_recent_lessons_group_by_the_mark_newest_first_and_only_that_goal(
    test_db, test_user, goal_factory, lesson_factory
):
    goal = await goal_factory(test_user)
    other = await goal_factory(test_user, name="Chess")
    await lesson_factory(goal, days_ago(2), correct=1, size=4, seconds=5)
    recent = await lesson_factory(goal, days_ago(1), correct=4, size=4, seconds=10)
    await lesson_factory(other, days_ago(0), correct=0, size=2)

    lessons = await StudentAnswerRepository(test_db).list_recent_lessons_by_goal(goal.id, limit=10)

    assert [lesson.accuracy for lesson in lessons] == [100.0, 25.0]
    assert lessons[0].lesson_id == str(recent)
    assert lessons[0].total_seconds == 40


@pytest.mark.asyncio
async def test_answered_at_spans_goals_and_stops_at_this_student(
    test_db, test_user, student_factory, goal_factory, lesson_factory
):
    italian = await goal_factory(test_user)
    chess = await goal_factory(test_user, name="Chess")
    theirs = await goal_factory(await student_factory(email="o@example.com", google_id="o"))
    await lesson_factory(italian, days_ago(2))
    await lesson_factory(chess, days_ago(1))
    await lesson_factory(theirs, days_ago(0))

    repository = StudentAnswerRepository(test_db)

    assert await repository.last_answered_at(test_user.id) == days_ago(1)
    assert set(await repository.list_answered_at_by_student(test_user.id)) == {
        days_ago(1),
        days_ago(2),
    }


@pytest.mark.asyncio
async def test_the_goals_history_is_every_answer_in_order_with_its_correctness(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """What the rating is a function of (#62): one goal's answers, oldest first,
    each already judged against its own question's right index."""
    goal = await goal_factory(test_user)
    elsewhere = await question_factory(await goal_factory(test_user, name="Chess"), "not here")
    first = await question_factory(goal, "first", correct=1)
    second = await question_factory(goal, "second", correct=2)
    await answer_factory(first, correct=False, answered_at=days_ago(3))
    await answer_factory(second, correct=True, answered_at=days_ago(2))
    await answer_factory(first, correct=True, answered_at=days_ago(1))
    await answer_factory(elsewhere, correct=True, answered_at=days_ago(1))

    history = await StudentAnswerRepository(test_db).list_history_by_goal(goal.id)

    assert [record.question_id for record in history] == [first.id, second.id, first.id]
    assert [record.correct for record in history] == [False, True, True]
    assert [record.answered_at for record in history] == [days_ago(days) for days in (3, 2, 1)]


@pytest.mark.asyncio
async def test_the_pace_is_read_across_goals_newest_first_and_skips_untimed_answers(
    test_db, test_user, student_factory, goal_factory, question_factory, answer_factory
):
    """What sizes a lesson (#134): how fast this person answers, wherever he does it."""
    italian = await goal_factory(test_user)
    chess = await goal_factory(test_user, name="Chess")
    theirs = await goal_factory(await student_factory(email="o@example.com", google_id="o"))
    for goal, days, taken in (
        (italian, 3, 30),
        (chess, 2, 10),
        (italian, 1, None),
        (theirs, 1, 99),
    ):
        question = await question_factory(goal, f"q{days}-{taken}")
        answer = await answer_factory(question, correct=True, answered_at=days_ago(days))
        answer.total_seconds = taken
    await test_db.flush()

    seconds = await StudentAnswerRepository(test_db).list_recent_seconds(test_user.id, 10)

    assert seconds == [10, 30]  # newest first, the null left out, the other student's ignored
    assert await StudentAnswerRepository(test_db).list_recent_seconds(test_user.id, 1) == [10]
