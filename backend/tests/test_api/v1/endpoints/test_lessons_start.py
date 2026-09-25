import uuid

import pytest
from sqlalchemy import select

from backend.models.student_answer import StudentAnswer
from backend.services.lessons.pacing import MAX_QUESTIONS, MIN_QUESTIONS
from backend.tests.fixtures.lessons import at, days_ago


def url(goal_id):
    return f"/api/v1/goals/{goal_id}/lessons"


async def bank_of(goal, question_factory, size, first=0):
    """`size` questions of the goal, born a minute apart so their order is fixed."""
    return [await question_factory(goal, f"q{i}", created_at=at(i)) for i in range(first, size)]


@pytest.mark.asyncio
async def test_start_serves_the_bank_and_writes_nothing(
    auth_client, test_db, test_user, goal_factory, question_factory, answer_factory
):
    """Serving a lesson stores no row (#131): a lesson is not a table"""
    goal = await goal_factory(test_user)
    fresh = await question_factory(goal, "fresh", correct=2, created_at=at(1))
    missed = await question_factory(goal, "missed", created_at=at(0))
    await answer_factory(missed, correct=False, answered_at=days_ago(1))

    response = await auth_client.post(url(goal.id))

    assert response.status_code == 201
    body = response.json()
    assert {q["question"] for q in body["questions"]} == {"fresh", "missed"}
    assert body["questions"][0] == {
        "id": str(fresh.id),
        "question": "fresh",
        "choices": ["a", "b", "c", "d"],
        "correct_answer_index": 2,
    }
    assert "lesson_id" not in body
    stored = await test_db.execute(select(StudentAnswer.question_id))
    assert [row[0] for row in stored.all()] == [missed.id]


@pytest.mark.asyncio
async def test_a_quick_student_gets_more_questions_for_the_same_two_minutes(
    auth_client, test_db, test_user, student_factory, goal_factory, question_factory, answer_factory
):
    """#134: nine seconds an answer, so two minutes is twelve questions, not eight"""
    quick = await goal_factory(test_user, name="Quick")
    for question in await bank_of(quick, question_factory, 20):
        await answer_factory(
            question, correct=True, answered_at=days_ago(20), lesson_id=uuid.uuid4()
        )
    for answer in (await test_db.execute(select(StudentAnswer))).scalars().all():
        answer.total_seconds = 9
    await test_db.flush()

    served = (await auth_client.post(url(quick.id))).json()["questions"]

    assert len(served) == MAX_QUESTIONS == 12  # 120 / 9 is 13, and the ceiling is 12
    assert len(served) > MIN_QUESTIONS


@pytest.mark.asyncio
async def test_a_student_who_thinks_hard_gets_the_floor_of_six(
    auth_client, test_db, test_user, goal_factory, question_factory, answer_factory
):
    """Forty seconds a question: six of them is already over two minutes"""
    goal = await goal_factory(test_user)
    for question in await bank_of(goal, question_factory, 20):
        await answer_factory(
            question, correct=True, answered_at=days_ago(20), lesson_id=uuid.uuid4()
        )
    for answer in (await test_db.execute(select(StudentAnswer))).scalars().all():
        answer.total_seconds = 40
    await test_db.flush()

    served = (await auth_client.post(url(goal.id))).json()["questions"]

    assert len(served) == MIN_QUESTIONS == 6


@pytest.mark.asyncio
async def test_a_students_first_lesson_is_the_floor(
    auth_client, test_user, goal_factory, question_factory
):
    """No answers at all, so no pace: six, not a guess"""
    goal = await goal_factory(test_user)
    await bank_of(goal, question_factory, 20)

    assert len((await auth_client.post(url(goal.id))).json()["questions"]) == MIN_QUESTIONS


@pytest.mark.asyncio
async def test_the_same_bank_at_the_same_hour_serves_the_same_lesson(
    auth_client, test_user, goal_factory, question_factory
):
    """Deterministic end to end, not only in the service"""
    goal = await goal_factory(test_user)
    await bank_of(goal, question_factory, 20)

    served = [
        [q["id"] for q in (await auth_client.post(url(goal.id))).json()["questions"]]
        for _ in range(3)
    ]

    assert served[0] == served[1] == served[2]


@pytest.mark.asyncio
async def test_no_gemini_client_is_ever_built_while_a_lesson_is_opened(
    auth_client, test_user, goal_factory, question_factory, monkeypatch
):
    """#134: choosing questions is arithmetic - proved by making a call impossible"""
    import google.genai

    def forbidden(*args, **kwargs):
        raise AssertionError("the selection path reached Gemini")

    monkeypatch.setattr(google.genai, "Client", forbidden)
    goal = await goal_factory(test_user)
    await bank_of(goal, question_factory, 20)

    response = await auth_client.post(url(goal.id))

    assert response.status_code == 201
    assert len(response.json()["questions"]) == MIN_QUESTIONS


@pytest.mark.asyncio
async def test_a_bank_shorter_than_a_lesson_serves_what_it_has(
    auth_client, test_user, goal_factory, question_factory
):
    """The size is a cap, not a floor - a thin bank still opens a lesson"""
    goal = await goal_factory(test_user)
    await bank_of(goal, question_factory, 3)

    response = await auth_client.post(url(goal.id))

    assert response.status_code == 201
    assert len(response.json()["questions"]) == 3


@pytest.mark.asyncio
async def test_start_on_an_empty_bank_is_409(auth_client, test_user, goal_factory):
    """The first bank is still being generated: say so, open nothing"""
    goal = await goal_factory(test_user)

    response = await auth_client.post(url(goal.id))

    assert response.status_code == 409
    assert response.json()["detail"] == "Lessons are still being prepared"


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
