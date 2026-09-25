"""Questions are generated when tomorrow's lesson would be too easy (#135).

Every test here builds a **real history** - questions, answers, the option the
student picked - and runs the step against it. Nothing mocks the rule: what is
asserted is either that Gemini was never called, or what it was called with, and
the prompt is rendered from those arguments and read.

The inventory rule this replaces (#91) counted the servable bank. Two of the
tests below are the cases where the two rules disagree: a short bank he keeps
missing, which the old rule would have topped up, and a deep bank of questions
he can answer, which the old rule would have left alone.
"""

import pytest

from backend.repositories.question_repository import QuestionRepository
from backend.services.gemini.lesson.prompt import get_lesson_generation_prompt
from backend.services.jobs.steps.questions import run_questions_step
from backend.services.lessons.generation import GENERATION_MARGIN
from backend.tests.fixtures.jobs import chain_gemini, generated
from backend.tests.fixtures.lessons import at
from backend.utils.envs import QUESTIONS_PER_GENERATION

# Italian, so the option the student picked reads as a belief and not as "b".
ITALIAN = ("hello", "goodbye", "please", "thank you")


async def answered(test_db, goal, question_factory, answer_factory, right: int, wrong: int):
    """A bank of questions the student has answered, `right` of them correctly.

    Each is answered twice, which is what makes the two students unambiguous:
    one ends well under the rating he started at, with questions that have
    proved hard against him, and the other the opposite.
    """
    for i in range(right):
        question = await question_factory(goal, text=f"right-{i}")
        for attempt in range(2):
            await answer_factory(question, True, at(i * 2 + attempt))
    for i in range(wrong):
        question = await question_factory(goal, text=f"wrong-{i}")
        for attempt in range(2):
            await answer_factory(question, False, at(i * 2 + attempt))
    await test_db.commit()


def asked(calls) -> tuple:
    """The arguments of the one generation call this night made."""
    return dict(calls)["questions"]


@pytest.mark.asyncio
async def test_a_student_who_keeps_missing_his_questions_gets_nothing(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """His bank already holds what he needs: the tokens would buy him nothing"""
    goal = await goal_factory(test_user)
    await answered(test_db, goal, question_factory, answer_factory, right=0, wrong=10)

    calls = []
    with chain_gemini(test_db, calls):
        assert await run_questions_step(test_db, str(test_user.id)) == 0

    assert calls == []


@pytest.mark.asyncio
async def test_a_short_bank_he_keeps_missing_is_still_nothing(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """Three questions is less than a lesson, and the old rule (#91) would have
    topped it up. Nothing counts rows now: he is not short of material"""
    goal = await goal_factory(test_user)
    await answered(test_db, goal, question_factory, answer_factory, right=0, wrong=3)

    calls = []
    with chain_gemini(test_db, calls):
        assert await run_questions_step(test_db, str(test_user.id)) == 0

    assert calls == []


@pytest.mark.asyncio
async def test_a_student_who_never_misses_gets_eight_aimed_above_his_rating(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """The target reaches the prompt as a number, and it is above where he is"""
    goal = await goal_factory(test_user, rating=1400)
    await answered(test_db, goal, question_factory, answer_factory, right=10, wrong=0)

    calls = []
    with chain_gemini(test_db, calls, questions=generated(*[0] * QUESTIONS_PER_GENERATION)):
        assert await run_questions_step(test_db, str(test_user.id)) == QUESTIONS_PER_GENERATION

    assert (asked(calls)[3], asked(calls)[4]) == (1400, 1400 + GENERATION_MARGIN)
    prompt = get_lesson_generation_prompt(*asked(calls))
    assert "**Write these questions at difficulty 1432**" in prompt
    assert f"exactly {QUESTIONS_PER_GENERATION} multiple-choice" in prompt


@pytest.mark.asyncio
async def test_a_deep_bank_he_can_answer_still_buys_eight(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """Twenty questions he has never seen: the old rule called that covered.
    A bank being large says nothing - he can answer these, so he needs more"""
    goal = await goal_factory(test_user)
    await answered(test_db, goal, question_factory, answer_factory, right=10, wrong=0)
    for i in range(20):
        await question_factory(goal, text=f"unseen-{i}")
    await test_db.commit()

    calls = []
    with chain_gemini(test_db, calls):
        await run_questions_step(test_db, str(test_user.id))

    assert [name for name, _ in calls] == ["questions"]


@pytest.mark.asyncio
async def test_the_prompt_carries_his_own_questions_and_the_option_he_chose(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """A wrong answer says little; which wrong answer says what he believes"""
    goal = await goal_factory(test_user)
    await answered(test_db, goal, question_factory, answer_factory, right=8, wrong=0)
    missed = await question_factory(goal, text="What is 'ciao'?", correct=0, options=ITALIAN)
    await answer_factory(missed, False, at(99))
    held = await question_factory(goal, text="What is 'grazie'?", correct=3, options=ITALIAN)
    await answer_factory(held, True, at(98))
    await test_db.commit()

    calls = []
    with chain_gemini(test_db, calls):
        await run_questions_step(test_db, str(test_user.id))

    prompt = get_lesson_generation_prompt(*asked(calls))
    assert '- "What is \'ciao\'?" -> he chose "goodbye", and the answer was "hello"' in prompt
    assert '- "What is \'grazie\'?" -> he answered "thank you"' in prompt


@pytest.mark.asyncio
async def test_an_empty_bank_is_the_goals_first_batch(test_db, test_user, goal_factory):
    """A goal created minutes ago: nothing to be too easy yet, so eight of them"""
    await goal_factory(test_user)

    calls = []
    with chain_gemini(test_db, calls, questions=generated(*[0] * QUESTIONS_PER_GENERATION)):
        assert await run_questions_step(test_db, str(test_user.id)) == QUESTIONS_PER_GENERATION

    assert asked(calls)[4] == 1200 + GENERATION_MARGIN


@pytest.mark.asyncio
async def test_each_goal_is_decided_on_its_own(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """A bank he is drowning in says nothing about the goal he is walking through"""
    law = await goal_factory(test_user, name="Law", description="Roman law.")
    history = await goal_factory(test_user, name="History", description="The 1800s.")
    await answered(test_db, law, question_factory, answer_factory, right=0, wrong=10)
    await answered(test_db, history, question_factory, answer_factory, right=10, wrong=0)

    calls = []
    with chain_gemini(test_db, calls):
        await run_questions_step(test_db, str(test_user.id))

    assert [name for name, _ in calls] == ["questions"]
    assert asked(calls)[0] == "History"
    assert await QuestionRepository(test_db).list_bank_history(law.id) != []


@pytest.mark.asyncio
async def test_the_questions_aim_at_the_frontier_and_not_at_the_description(
    test_db, test_user, goal_factory
):
    """#133: the day-one description is background, the frontier is the target"""
    goal = await goal_factory(test_user)

    calls = []
    with chain_gemini(test_db, calls):
        await run_questions_step(test_db, str(test_user.id))

    name, description, frontier = asked(calls)[:3]
    assert (name, description) == (goal.name, goal.description)
    assert frontier == goal.description  # the goal's first frontier, written with it
