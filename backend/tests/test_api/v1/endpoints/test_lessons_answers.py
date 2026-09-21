import uuid
from unittest.mock import patch

import pytest
import pytest_asyncio

from backend.repositories.lesson_answer_repository import LessonAnswerRepository
from backend.repositories.lesson_repository import LessonRepository
from backend.tests.fixtures.lessons import at

DELTA = "backend.api.v1.endpoints.lessons.lesson_elo_delta"


def url(goal_id, lesson_id):
    return f"/api/v1/goals/{goal_id}/lessons/{lesson_id}/answers"


def answer(question, choice, seconds=10, **extra):
    return {"question_id": str(question.id), "choice_index": choice, "seconds_spent": seconds, **extra}


@pytest_asyncio.fixture
async def opened(auth_client, test_user, goal_factory, question_factory):
    """A goal at rating 1200 with a started lesson of two questions, both correct at index 1."""
    goal = await goal_factory(test_user, rating=1200)
    first = await question_factory(goal, "first", correct=1, created_at=at(0))
    second = await question_factory(goal, "second", correct=1, created_at=at(1))
    response = await auth_client.post(f"/api/v1/goals/{goal.id}/lessons")
    return goal, response.json()["lesson_id"], first, second


@pytest.mark.asyncio
async def test_answers_are_graded_server_side_and_move_the_rating(auth_client, test_db, opened):
    """Right, then wrong despite the client's claims: 50%, the patched delta applied"""
    goal, lesson_id, first, second = opened
    faked = answer(second, 3, seconds=20, is_correct=True, correct_answer_index=3)
    body = {"answers": [answer(first, 1), faked], "student_accuracy": 100.0, "elo": 99}

    with patch(DELTA, return_value=7):
        response = await auth_client.post(url(goal.id, lesson_id), json=body)

    assert response.status_code == 200
    assert response.json() == {"total_seconds_spent": 30, "student_accuracy": 50.0, "elo": 7}
    await test_db.refresh(goal)
    assert goal.rating == 1207
    lesson = await LessonRepository(test_db).get_by_id(lesson_id)
    assert (lesson.accuracy, lesson.total_seconds, lesson.elo_delta, lesson.elo_after) == (50.0, 30, 7, 1207)
    assert lesson.finished_at is not None
    stored = {a.question_id: a.is_correct for a in await LessonAnswerRepository(test_db).list_by_lesson(lesson.id)}
    assert stored == {first.id: True, second.id: False}


@pytest.mark.asyncio
async def test_a_submit_bumps_the_goals_updated_at_and_records_the_new_rating(
    auth_client, test_db, test_user, goal_factory, question_factory
):
    """#72: the rating moves in one UPDATE, which must still move `updated_at`"""
    goal = await goal_factory(test_user, rating=1000, created_at=at(0), updated_at=at(0))
    question = await question_factory(goal, "only", correct=0)
    lesson_id = (await auth_client.post(f"/api/v1/goals/{goal.id}/lessons")).json()["lesson_id"]

    with patch(DELTA, return_value=-4):
        await auth_client.post(url(goal.id, lesson_id), json={"answers": [answer(question, 0)]})

    await test_db.refresh(goal)
    lesson = await LessonRepository(test_db).get_by_id(lesson_id)
    assert (goal.rating, lesson.elo_after) == (996, 996)
    assert goal.updated_at > at(60)


@pytest.mark.asyncio
async def test_an_unanswered_question_counts_as_wrong(auth_client, opened):
    goal, lesson_id, first, _ = opened
    response = await auth_client.post(url(goal.id, lesson_id), json={"answers": [answer(first, 1)]})
    assert response.json()["student_accuracy"] == 50.0


@pytest.mark.asyncio
async def test_a_second_submit_is_409(auth_client, opened):
    goal, lesson_id, first, second = opened
    body = {"answers": [answer(first, 1), answer(second, 1)]}
    assert (await auth_client.post(url(goal.id, lesson_id), json=body)).status_code == 200
    assert (await auth_client.post(url(goal.id, lesson_id), json=body)).status_code == 409


@pytest.mark.asyncio
async def test_an_unserved_question_is_422_and_stores_nothing(
    auth_client, test_db, opened, question_factory
):
    goal, lesson_id, first, _ = opened
    unserved = await question_factory(goal, "not in this lesson")
    body = {"answers": [answer(first, 1), answer(unserved, 1)]}

    assert (await auth_client.post(url(goal.id, lesson_id), json=body)).status_code == 422
    assert await LessonAnswerRepository(test_db).list_by_lesson(lesson_id) == []


@pytest.mark.asyncio
async def test_the_same_question_twice_is_422(auth_client, opened):
    goal, lesson_id, first, _ = opened
    body = {"answers": [answer(first, 1), answer(first, 0)]}
    assert (await auth_client.post(url(goal.id, lesson_id), json=body)).status_code == 422


@pytest.mark.asyncio
async def test_a_lesson_of_another_goal_is_404(auth_client, test_user, goal_factory, opened):
    _, lesson_id, first, _ = opened
    other_goal = await goal_factory(test_user, name="Chess")
    body = {"answers": [answer(first, 1)]}
    for goal_id, lesson in ((other_goal.id, lesson_id), (opened[0].id, uuid.uuid4())):
        assert (await auth_client.post(url(goal_id, lesson), json=body)).status_code == 404


@pytest.mark.asyncio
async def test_someone_elses_goal_is_404(auth_client, student_factory, goal_factory, opened):
    _, lesson_id, first, _ = opened
    other = await student_factory(email="o@example.com", google_id="other")
    foreign = await goal_factory(other)
    body = {"answers": [answer(first, 1)]}
    assert (await auth_client.post(url(foreign.id, lesson_id), json=body)).status_code == 404
