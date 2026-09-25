"""`make claude`'s seeder: Fictitious Claude with a lived-in history (#60)."""

from datetime import date

import pytest

from backend.core import clock
from backend.repositories.chat_message_repository import ChatMessageRepository
from backend.repositories.question_repository import QuestionRepository
from backend.repositories.resource_repository import ResourceRepository
from backend.repositories.student_answer_repository import StudentAnswerRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.fictitious.history_data import LESSON_SIZE, START_RATING
from backend.services.fictitious.seeder import seed_fictitious_student
from backend.services.lessons.streak import student_streak


async def active_goal(db, result):
    return next(g for g in result.goals if g.id == result.student.current_goal_id)


async def lessons_of(db, goal_id, limit=50):
    """The goal's lessons as Home reads them: answers grouped by their mark."""
    return await StudentAnswerRepository(db).list_recent_lessons_by_goal(goal_id, limit)


@pytest.mark.asyncio
async def test_the_student_is_fictitious_claude(test_db):
    student = (await seed_fictitious_student(test_db)).student
    assert student.name == "Fictitious Claude"
    assert student.google_id == "fictitious-claude"
    assert student.email == "fictitious-claude@fictitious.invalid"


@pytest.mark.asyncio
async def test_it_creates_the_history(test_db):
    result = await seed_fictitious_student(test_db)
    goal = await active_goal(test_db, result)
    lessons = await lessons_of(test_db, goal.id)
    chat = await ChatMessageRepository(test_db).list_by_goal(goal.id, 50)
    kinds = [r.resource_type.value for r in await ResourceRepository(test_db).list_by_goal(goal.id)]

    assert result.created and len(result.goals) == 3
    assert len({g.name for g in result.goals}) == 3
    assert len(await QuestionRepository(test_db).list_bank_history(goal.id)) == 15
    assert len(lessons) == 16
    for lesson in lessons:
        batch = await StudentAnswerRepository(test_db).list_by_lesson(lesson.lesson_id)
        assert [a.position for a in batch] == list(range(LESSON_SIZE))
    assert len(chat) == 8
    assert sum(ex.is_liked for ex in chat) == 1
    assert any(len(ex.tutor_responses) > 1 for ex in chat)
    assert sorted(kinds) == ["pdf"] * 3 + ["webpage"] * 3 + ["youtube"] * 3
    assert len(await StudentContextRepository(test_db).list_valid(result.student.id)) == 1


@pytest.mark.asyncio
async def test_every_goal_ends_above_where_it_started(test_db):
    """The seeded elo now lands only on the goal's rating: there is nowhere
    else to put it since the `lessons` table went (#131)."""
    for goal in (await seed_fictitious_student(test_db)).goals:
        assert goal.rating != START_RATING


@pytest.mark.asyncio
async def test_the_streak_is_real(test_db):
    student = (await seed_fictitious_student(test_db)).student
    assert 1 < await student_streak(test_db, student.id) < 14


@pytest.mark.asyncio
async def test_a_rerun_writes_nothing(test_db):
    first = await seed_fictitious_student(test_db)
    goal = await active_goal(test_db, first)
    second = await seed_fictitious_student(test_db)

    assert not second.created
    assert second.student.id == first.student.id
    assert {g.id for g in second.goals} == {g.id for g in first.goals}
    assert len(await lessons_of(test_db, goal.id)) == 16
    assert len(await ChatMessageRepository(test_db).list_by_goal(goal.id, 50)) == 8


@pytest.mark.asyncio
async def test_fresh_rebuilds_the_student(test_db):
    first = await seed_fictitious_student(test_db)
    fresh = await seed_fictitious_student(test_db, fresh=True)

    assert fresh.created
    assert fresh.student.id != first.student.id
    assert len(fresh.goals) == 3
    assert await lessons_of(test_db, first.goals[0].id) == []


@pytest.mark.asyncio
async def test_it_reuses_a_student_dev_login_made(test_db, student_factory):
    """`make claude-token` may have run first: the history goes on that row."""
    existing = await student_factory(
        name="Fictitious Claude",
        google_id="fictitious-claude",
        email="fictitious-claude@fictitious.invalid",
    )
    result = await seed_fictitious_student(test_db)
    assert result.created and result.student.id == existing.id


@pytest.mark.asyncio
async def test_the_seeded_hours_are_the_students_wall_clock(test_db):
    """#92: history_data's hours are the student's. The plan has a lesson 10
    days ago at 22:00, which is 01:00 UTC the next day - it must read back at
    22:00 app-local, on the day the student lived it and not the one after."""
    seeded_at = clock.app_moment(date(2026, 9, 24), 12)
    result = await seed_fictitious_student(test_db, now=seeded_at)
    goal = await active_goal(test_db, result)
    lessons = await lessons_of(test_db, goal.id)

    late = [lesson for lesson in lessons if clock.app_local(lesson.answered_at).hour == 22]
    assert len(late) == 1
    assert late[0].answered_at.tzinfo is not None
    assert clock.app_date(late[0].answered_at) == date(2026, 9, 14)
