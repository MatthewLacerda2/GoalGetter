import pytest
from sqlalchemy import select

from backend.models.lesson import Lesson
from backend.repositories.lesson_repository import LessonRepository
from backend.tests.fixtures.lessons import at
from backend.utils.envs import QUESTIONS_PER_LESSON


def url(goal_id):
    return f"/api/v1/goals/{goal_id}/lessons"


@pytest.mark.asyncio
async def test_start_serves_recent_mistakes_first_and_records_the_lesson(
    auth_client, test_db, test_user, goal_factory, question_factory, answer_factory
):
    """The question just got wrong leads; the lesson stores what it served"""
    goal = await goal_factory(test_user)
    fresh = await question_factory(goal, "fresh", correct=2)
    missed = await question_factory(goal, "missed")
    await answer_factory(missed, correct=False, answered_at=at(5))

    response = await auth_client.post(url(goal.id))

    assert response.status_code == 201
    body = response.json()
    assert [q["question"] for q in body["questions"]] == ["missed", "fresh"]
    assert body["questions"][1] == {
        "id": str(fresh.id),
        "question": "fresh",
        "choices": ["a", "b", "c", "d"],
        "correct_answer_index": 2,
    }
    lesson = await LessonRepository(test_db).get_by_id(body["lesson_id"])
    assert lesson.question_ids == [missed.id, fresh.id]
    assert lesson.finished_at is None


@pytest.mark.asyncio
async def test_a_lesson_is_eight_questions(auth_client, test_user, goal_factory, question_factory):
    """#86: the size the user decided on, spelled out and not only as the constant"""
    assert QUESTIONS_PER_LESSON == 8
    goal = await goal_factory(test_user)
    for i in range(QUESTIONS_PER_LESSON + 2):
        await question_factory(goal, f"q{i}", created_at=at(i))

    response = await auth_client.post(url(goal.id))
    assert len(response.json()["questions"]) == 8


@pytest.mark.asyncio
async def test_a_bank_shorter_than_a_lesson_serves_what_it_has(
    auth_client, test_user, goal_factory, question_factory
):
    """#86: the size is a cap, not a floor - a thin bank still opens a lesson"""
    goal = await goal_factory(test_user)
    for i in range(3):
        await question_factory(goal, f"q{i}", created_at=at(i))

    response = await auth_client.post(url(goal.id))

    assert response.status_code == 201
    assert len(response.json()["questions"]) == 3


@pytest.mark.asyncio
async def test_start_on_an_empty_bank_is_409(auth_client, test_db, test_user, goal_factory):
    """The first bank is still being generated: say so, open nothing"""
    goal = await goal_factory(test_user)

    response = await auth_client.post(url(goal.id))

    assert response.status_code == 409
    assert response.json()["detail"] == "Lessons are still being prepared"
    assert (await test_db.execute(select(Lesson).where(Lesson.goal_id == goal.id))).first() is None


@pytest.mark.asyncio
async def test_start_on_someone_elses_goal_is_404(
    auth_client, test_user, student_factory, goal_factory, question_factory
):
    other = await student_factory(email="o@example.com", google_id="other")
    goal = await goal_factory(other)
    await question_factory(goal)

    assert (await auth_client.post(url(goal.id))).status_code == 404


@pytest.mark.asyncio
async def test_start_requires_auth(client, test_user, goal_factory):
    goal = await goal_factory(test_user)
    assert (await client.post(url(goal.id))).status_code == 403
