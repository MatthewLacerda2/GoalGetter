"""Questions are generated only when tomorrow's lesson would run short (#91).

What "short" means is the selection rule the lesson endpoint already uses
(#55): a lesson is filled from the questions whose latest answer was wrong,
then the ones never answered. Those two together are the *servable* bank, and
they are what this step counts.

The step is exercised directly. Every test says either how many questions were
asked for, or that Gemini was never called at all - the second being the point
of the issue.
"""

import pytest

from backend.repositories.question_repository import QuestionRepository
from backend.services.jobs.steps.questions import TARGET_SERVABLE, run_questions_step
from backend.tests.fixtures.jobs import chain_gemini, generated
from backend.tests.fixtures.lessons import at
from backend.utils.envs import QUESTIONS_PER_LESSON


async def bank(test_db, goal, question_factory, answer_factory, never=0, wrong=0, right=0):
    """A bank of questions in the three states selection distinguishes."""
    for i in range(never):
        await question_factory(goal, text=f"never-{i}")
    for i in range(wrong):
        await answer_factory(await question_factory(goal, text=f"wrong-{i}"), False, at(i))
    for i in range(right):
        await answer_factory(await question_factory(goal, text=f"right-{i}"), True, at(i))
    await test_db.commit()


def asked_for(calls) -> int:
    """How many questions the one generation call asked Gemini for."""
    return dict(calls)["questions"][5]


@pytest.mark.asyncio
async def test_a_full_bank_generates_nothing(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """A lesson's worth of unseen questions is tomorrow covered: no call at all"""
    goal = await goal_factory(test_user)
    await bank(test_db, goal, question_factory, answer_factory, never=QUESTIONS_PER_LESSON)

    calls = []
    with chain_gemini(test_db, calls):
        assert await run_questions_step(test_db, str(test_user.id)) == 0

    assert calls == []


@pytest.mark.asyncio
async def test_a_bank_the_student_keeps_getting_wrong_generates_nothing(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """Struggling makes our job cheaper: a wrong answer keeps its question in rotation"""
    goal = await goal_factory(test_user)
    await bank(test_db, goal, question_factory, answer_factory, wrong=QUESTIONS_PER_LESSON)

    calls = []
    with chain_gemini(test_db, calls):
        assert await run_questions_step(test_db, str(test_user.id)) == 0

    assert calls == []


@pytest.mark.asyncio
async def test_an_empty_bank_generates_a_lesson_plus_the_margin(test_db, test_user, goal_factory):
    """Nothing to serve: ask for tomorrow's lesson and one lesson of margin"""
    await goal_factory(test_user)

    calls = []
    with chain_gemini(test_db, calls, questions=generated(*range(TARGET_SERVABLE))):
        assert await run_questions_step(test_db, str(test_user.id)) == 4

    assert asked_for(calls) == TARGET_SERVABLE == 2 * QUESTIONS_PER_LESSON


@pytest.mark.asyncio
async def test_a_bank_answered_right_is_as_empty_as_no_bank(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """A question the student got right is not servable: it does not fill tomorrow"""
    goal = await goal_factory(test_user)
    await bank(test_db, goal, question_factory, answer_factory, right=8)

    calls = []
    with chain_gemini(test_db, calls):
        await run_questions_step(test_db, str(test_user.id))

    assert asked_for(calls) == TARGET_SERVABLE


@pytest.mark.asyncio
async def test_a_half_full_bank_is_topped_up_to_the_target(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """Only the gap is bought, and the margin above it - never a fixed batch"""
    goal = await goal_factory(test_user)
    await bank(test_db, goal, question_factory, answer_factory, never=1, wrong=1, right=3)

    calls = []
    with chain_gemini(test_db, calls):
        await run_questions_step(test_db, str(test_user.id))

    assert asked_for(calls) == TARGET_SERVABLE - 2


@pytest.mark.asyncio
async def test_the_mistakes_in_the_prompt_are_the_newest_first(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """The same reading of the bank, used twice: to count it and to aim at it"""
    goal = await goal_factory(test_user)
    await bank(test_db, goal, question_factory, answer_factory, wrong=2)

    calls = []
    with chain_gemini(test_db, calls):
        await run_questions_step(test_db, str(test_user.id))

    assert dict(calls)["questions"][4] == ["wrong-1", "wrong-0"]
    assert asked_for(calls) == TARGET_SERVABLE - 2


@pytest.mark.asyncio
async def test_each_goal_is_counted_on_its_own(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """A deep bank in law says nothing about tomorrow's history lesson"""
    law = await goal_factory(test_user, name="Law", description="Roman law.")
    await goal_factory(test_user, name="History", description="The 1800s.")
    await bank(test_db, law, question_factory, answer_factory, never=QUESTIONS_PER_LESSON)

    calls = []
    with chain_gemini(test_db, calls):
        await run_questions_step(test_db, str(test_user.id))

    assert [name for name, _ in calls] == ["questions"]
    assert await QuestionRepository(test_db).list_bank_history(law.id) != []
