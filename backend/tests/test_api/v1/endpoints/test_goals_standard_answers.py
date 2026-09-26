"""What the student tells us about himself while his first batch generates (#132).

The four questions are ours, so the wire carries keys in both directions and the
sentences the database keeps come from
`backend/services/onboarding/standard_questions.py`. Nothing here blocks: a
partial list, an empty one and a key this build does not know are all answered
201-style rather than refused, because the student is on his way to a lesson.
"""

import pytest

from backend.repositories.onboarding_repository import OnboardingRepository
from backend.services.onboarding.standard_questions import STANDARD_QUESTIONS, SYSTEM_AUTHOR

AGE, PURPOSE = STANDARD_QUESTIONS[0], STANDARD_QUESTIONS[1]


def url(goal) -> str:
    return f"/api/v1/goals/{goal.id}/standard-answers"


def answer(question, index: int) -> dict:
    return {"question_key": question.key, "option_key": question.options[index].key}


@pytest.mark.asyncio
async def test_the_answers_are_stored_as_the_student_read_them(
    auth_client, test_db, test_user, goal_factory
):
    """All four options and the index of the one picked - the shape the table was
    built for, which only a question we wrote ourselves can fill"""
    goal = await goal_factory(test_user)

    response = await auth_client.post(url(goal), json={"answers": [answer(AGE, 2)]})

    assert response.status_code == 204
    row = (await OnboardingRepository(test_db).list_by_student(test_user.id))[0]
    assert row.question == AGE.text
    assert [row.option_a, row.option_b, row.option_c, row.option_d] == [
        option.text for option in AGE.options
    ]
    assert row.selected_option_index == 2
    assert OnboardingRepository.answer_of(row) == AGE.options[2].text


@pytest.mark.asyncio
async def test_a_standard_row_says_no_model_wrote_it(auth_client, test_db, test_user, goal_factory):
    """One read of a student's onboarding tells ours from Gemini's (#132)"""
    goal = await goal_factory(test_user)

    await auth_client.post(url(goal), json={"answers": [answer(AGE, 0), answer(PURPOSE, 1)]})

    rows = await OnboardingRepository(test_db).list_by_student(test_user.id)
    assert [row.ai_model for row in rows] == [SYSTEM_AUTHOR, SYSTEM_AUTHOR]


@pytest.mark.asyncio
async def test_a_key_this_build_does_not_know_is_dropped(
    auth_client, test_db, test_user, goal_factory
):
    """An older client costs the student one fact, never his lesson"""
    goal = await goal_factory(test_user)
    unknown = {"question_key": "favourite-colour", "option_key": "blue"}

    response = await auth_client.post(url(goal), json={"answers": [unknown, answer(AGE, 0)]})

    assert response.status_code == 204
    rows = await OnboardingRepository(test_db).list_by_student(test_user.id)
    assert [row.question for row in rows] == [AGE.text]


@pytest.mark.asyncio
async def test_skipping_every_question_stores_nothing(
    auth_client, test_db, test_user, goal_factory
):
    """He skipped through to his lesson, which is allowed and costs nothing"""
    goal = await goal_factory(test_user)

    response = await auth_client.post(url(goal), json={"answers": []})

    assert response.status_code == 204
    assert await OnboardingRepository(test_db).list_by_student(test_user.id) == []


@pytest.mark.asyncio
async def test_someone_elses_goal_is_not_found(
    auth_client, test_user, student_factory, goal_factory
):
    """The ownership rule every /goals/{goal_id} route answers with (404, not 403)"""
    other = await student_factory(email="o@example.com", google_id="other")
    goal = await goal_factory(other)

    response = await auth_client.post(url(goal), json={"answers": [answer(AGE, 0)]})

    assert response.status_code == 404


@pytest.mark.asyncio
async def test_each_answer_keeps_how_long_he_took(auth_client, test_db, test_user, goal_factory):
    """The seconds the app measured travel with the answer they belong to (#174)"""
    goal = await goal_factory(test_user)
    answers = [{**answer(AGE, 0), "total_seconds": 4}, {**answer(PURPOSE, 1), "total_seconds": 9}]

    await auth_client.post(url(goal), json={"answers": answers})

    rows = await OnboardingRepository(test_db).list_by_student(test_user.id)
    assert {row.question: row.total_seconds for row in rows} == {AGE.text: 4, PURPOSE.text: 9}


@pytest.mark.asyncio
async def test_an_answer_without_a_duration_is_still_stored(
    auth_client, test_db, test_user, goal_factory
):
    """A missing duration loses the duration, not the answer (#174)"""
    goal = await goal_factory(test_user)

    response = await auth_client.post(url(goal), json={"answers": [answer(AGE, 3)]})

    assert response.status_code == 204
    row = (await OnboardingRepository(test_db).list_by_student(test_user.id))[0]
    assert (row.selected_option_index, row.total_seconds) == (3, None)
