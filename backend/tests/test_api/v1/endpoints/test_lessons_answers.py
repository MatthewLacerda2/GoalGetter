"""Submitting a lesson: one batch, one minted `lesson_id`, one row per answer (#131)."""

import uuid

import pytest
import pytest_asyncio

from backend.repositories.student_answer_repository import StudentAnswerRepository
from backend.tests.fixtures.lessons import at
from backend.utils.envs import QUESTIONS_PER_LESSON


def url(goal_id):
    return f"/api/v1/goals/{goal_id}/lessons/answers"


def answer(question, choice, seconds=10, **extra):
    return {
        "question_id": str(question.id),
        "choice_index": choice,
        "seconds_spent": seconds,
        **extra,
    }


async def stored_answers(test_db, test_user):
    """Every answer the student has, newest first, with its question."""
    return await StudentAnswerRepository(test_db).list_recent_by_student(test_user.id, 100)


@pytest_asyncio.fixture
async def opened(test_user, goal_factory, question_factory):
    """A goal at rating 1200 with two bank questions, both right at index 1."""
    goal = await goal_factory(test_user, rating=1200)
    first = await question_factory(goal, "first", correct=1, created_at=at(0))
    second = await question_factory(goal, "second", correct=1, created_at=at(1))
    return goal, first, second


@pytest.mark.asyncio
async def test_answers_are_graded_server_side_and_move_the_rating(
    auth_client, test_db, test_user, opened
):
    """Right, then wrong despite the client's claims: 50%, and 50% is below par.

    Both questions are new, so both are worth what the goal was worth when they
    were generated: E is 0.625 against each (#62), because a quarter of any
    right answer is the four options. One right and one wrong is under that, so
    a lesson graded 50% costs rating: 1200 -> 1190.
    """
    goal, first, second = opened
    faked = answer(second, 3, seconds=20, is_correct=True, correct_answer_index=3)
    body = {"answers": [answer(first, 1), faked], "student_accuracy": 100.0, "elo": 99}

    response = await auth_client.post(url(goal.id), json=body)

    assert response.status_code == 200
    assert response.json() == {"total_seconds_spent": 30, "student_accuracy": 50.0, "elo": -10}
    await test_db.refresh(goal)
    assert goal.rating == 1190
    stored = {a.question_id: a.selected_index for a, _ in await stored_answers(test_db, test_user)}
    assert stored == {first.id: 1, second.id: 3}


@pytest.mark.asyncio
async def test_one_submission_is_one_lesson_id_and_two_are_two(
    auth_client, test_db, test_user, opened
):
    """The mark the backend mints groups a batch and nothing else (#131)"""
    goal, first, second = opened
    body = {"answers": [answer(first, 1), answer(second, 1)]}

    await auth_client.post(url(goal.id), json=body)
    await auth_client.post(url(goal.id), json=body)

    answers = [a for a, _ in await stored_answers(test_db, test_user)]
    marks = {a.lesson_id for a in answers}
    assert len(answers) == 4
    assert len(marks) == 2
    for mark in marks:
        batch = await StudentAnswerRepository(test_db).list_by_lesson(mark)
        assert [a.position for a in batch] == [0, 1]
        assert [a.question_id for a in batch] == [first.id, second.id]


@pytest.mark.asyncio
async def test_answering_the_same_question_again_adds_a_row_rather_than_replacing_one(
    auth_client, test_db, test_user, opened
):
    """Nothing is ever overwritten: the history is what says whether he learned"""
    goal, first, _ = opened

    for choice in (0, 1):
        await auth_client.post(url(goal.id), json={"answers": [answer(first, choice)]})

    history = await StudentAnswerRepository(test_db).list_for_question(first.id)
    assert [a.selected_index for a in history] == [0, 1]
    assert len({a.lesson_id for a in history}) == 2


@pytest.mark.asyncio
async def test_a_partial_submission_is_accepted(auth_client, test_db, test_user, opened):
    """The completeness rule of #86 is gone: nothing recorded what was served"""
    goal, first, _ = opened

    response = await auth_client.post(url(goal.id), json={"answers": [answer(first, 1)]})

    assert response.status_code == 200
    assert response.json()["student_accuracy"] == 100.0
    assert len(await stored_answers(test_db, test_user)) == 1


@pytest.mark.asyncio
async def test_no_answers_at_all_is_422(auth_client, opened):
    """An empty batch would mint a lesson mark over nothing"""
    goal, _, _ = opened
    assert (await auth_client.post(url(goal.id), json={"answers": []})).status_code == 422


@pytest.mark.asyncio
async def test_a_full_lesson_is_graded(
    auth_client, test_db, test_user, goal_factory, question_factory
):
    """Eight questions, all right: graded, nothing refused, 98 points of rating.

    Eight answers at a K that is still provisional (40, decaying as the evidence
    arrives) against a bank the student has never seen: a perfect first lesson
    is worth about a hundred points, and the second one will be worth less.
    """
    goal = await goal_factory(test_user, rating=1200)
    questions = [
        await question_factory(goal, f"q{i}", correct=i % 4, created_at=at(i))
        for i in range(QUESTIONS_PER_LESSON)
    ]
    body = {"answers": [answer(q, q.right_answer_index, seconds=15) for q in questions]}

    response = await auth_client.post(url(goal.id), json=body)

    assert response.status_code == 200
    assert response.json() == {"total_seconds_spent": 120, "student_accuracy": 100.0, "elo": 98}
    stored = [a for a, _ in await stored_answers(test_db, test_user)]
    assert len(stored) == QUESTIONS_PER_LESSON
    assert [a.total_seconds for a in stored] == [15] * QUESTIONS_PER_LESSON


@pytest.mark.asyncio
async def test_a_submit_bumps_the_goals_updated_at_and_moves_the_rating(
    auth_client, test_db, test_user, goal_factory, question_factory
):
    """#72: the rating moves in one UPDATE, which must still move `updated_at`"""
    goal = await goal_factory(test_user, rating=1200, created_at=at(0), updated_at=at(0))
    question = await question_factory(goal, "only", correct=0)

    await auth_client.post(url(goal.id), json={"answers": [answer(question, 0)]})

    await test_db.refresh(goal)
    assert goal.rating == 1215
    assert goal.updated_at > at(60)


@pytest.mark.asyncio
async def test_a_question_outside_the_goals_bank_is_422_and_stores_nothing(
    auth_client, test_db, test_user, goal_factory, question_factory, opened
):
    goal, first, _ = opened
    elsewhere = await question_factory(await goal_factory(test_user, name="Chess"), "not here")
    body = {"answers": [answer(first, 1), answer(elsewhere, 1)]}

    assert (await auth_client.post(url(goal.id), json=body)).status_code == 422
    assert await stored_answers(test_db, test_user) == []


@pytest.mark.asyncio
async def test_the_same_question_twice_in_one_batch_is_422(auth_client, opened):
    """Inside one lesson a question is asked once; twice is a broken client"""
    goal, first, _ = opened
    body = {"answers": [answer(first, 1), answer(first, 0)]}
    assert (await auth_client.post(url(goal.id), json=body)).status_code == 422


@pytest.mark.asyncio
async def test_an_unknown_question_id_is_422(auth_client, opened):
    goal, _, _ = opened
    body = {"answers": [{"question_id": str(uuid.uuid4()), "choice_index": 0, "seconds_spent": 1}]}
    assert (await auth_client.post(url(goal.id), json=body)).status_code == 422


@pytest.mark.asyncio
async def test_someone_elses_goal_is_404(auth_client, student_factory, goal_factory, opened):
    _, first, _ = opened
    other = await student_factory(email="o@example.com", google_id="other")
    foreign = await goal_factory(other)
    body = {"answers": [answer(first, 1)]}
    assert (await auth_client.post(url(foreign.id), json=body)).status_code == 404


@pytest.mark.asyncio
async def test_two_identical_histories_end_at_the_same_rating(
    auth_client, test_db, test_user, goal_factory, question_factory
):
    """Nothing random is left in grading (#62): the same answers over the same
    history land on the same number, and two goals are the proof."""
    outcomes = []
    for name in ("Italian", "Guitar"):
        goal = await goal_factory(test_user, name=name, rating=1200)
        bank = [
            await question_factory(goal, f"{name}-{i}", correct=1, created_at=at(i))
            for i in range(3)
        ]
        body = {"answers": [answer(bank[0], 1), answer(bank[1], 0), answer(bank[2], 1)]}
        deltas = [(await auth_client.post(url(goal.id), json=body)).json()["elo"] for _ in range(2)]
        await test_db.refresh(goal)
        outcomes.append((deltas, goal.rating))

    assert outcomes[0] == outcomes[1]
    assert outcomes[0][1] != 1200
