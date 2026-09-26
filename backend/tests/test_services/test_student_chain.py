"""The student chain: context, then questions, then resources (#88).

The scaffolding is in `fixtures/jobs.py`; what this module asserts is the
chain's own promises - the order of the steps, that each reads what the one
before it wrote, that a failure stops the chain and keeps what was written, and
that the caller decides whether resources are wanted at all (#89).
"""

import asyncio

import pytest

from backend.core import clock
from backend.core.language import Language
from backend.models.student_context import StudentContext
from backend.repositories.onboarding_repository import OnboardingRepository
from backend.repositories.question_repository import QuestionRepository
from backend.repositories.resource_repository import ResourceRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.jobs import student_chain
from backend.services.jobs.steps.resources import run_resources_step
from backend.services.jobs.student_chain import kickoff_student_chain, run_student_chain
from backend.services.lessons.generation import GENERATION_MARGIN
from backend.tests.fixtures.jobs import chain_gemini, resource, review
from backend.tests.fixtures.lessons import at

ANSWERS = [("Experience?", "None")]
PROMPT_PAIR = ("What do you want to learn?", "I want Italian")
MODEL = "gemini-test"

# One standard answer and the pair the prompt reads it back as (#132).
STANDARD = [("age", "18to24")]
STANDARD_PAIR = ("How old are you?", "18 to 24")


async def onboarded(test_db, goal, prompt="I want Italian", answers=ANSWERS):
    await OnboardingRepository(test_db).save_onboarding(goal.id, prompt, answers, MODEL)
    await test_db.commit()


async def answered_the_standard_questions(test_db, goal):
    """What the student fills the wait with, after goal creation has returned.
    Returns the moment goal creation pinned its own read of the onboarding to."""
    as_of = clock.now()
    await OnboardingRepository(test_db).save_standard_answers(goal.id, STANDARD)
    await test_db.commit()
    return as_of


@pytest.mark.asyncio
async def test_the_chain_runs_context_then_questions_then_resources(
    test_db, test_user, goal_factory
):
    """One student, one Gemini call at a time, always in that order"""
    goal = await goal_factory(test_user)
    await onboarded(test_db, goal)

    calls = []
    with chain_gemini(test_db, calls, found=[resource(goal.id, "https://good.dev/a")]):
        assert await run_student_chain(str(test_user.id)) == (True, 2, 1)

    assert [name for name, _ in calls] == ["context", "questions", "resources"]


@pytest.mark.asyncio
async def test_the_first_run_reads_the_onboarding_from_the_database(
    test_db, test_user, goal_factory
):
    """Nothing is handed to the chain: it reads the rows goal creation stored"""
    goal = await goal_factory(test_user)
    await onboarded(test_db, goal)

    calls = []
    with chain_gemini(test_db, calls):
        await run_student_chain(str(test_user.id))

    goals, prompt, questions_answers = dict(calls)["context"]
    assert [(g.name, g.description) for g in goals] == [(goal.name, goal.description)]
    assert prompt is None
    assert questions_answers == [PROMPT_PAIR, *ANSWERS]
    stored = await StudentContextRepository(test_db).list_valid(test_user.id)
    assert [(c.state, c.metacognition) for c in stored] == [("Beginner", "Curious")]


@pytest.mark.asyncio
async def test_questions_and_resources_read_the_context_the_chain_just_wrote(
    test_db, test_user, goal_factory
):
    """The later steps see the context of this run, not of the run before it"""
    goal = await goal_factory(test_user)
    await onboarded(test_db, goal)

    calls = []
    with chain_gemini(test_db, calls):
        await run_student_chain(str(test_user.id))

    seen = dict(calls)
    name, description, frontier, rating, target, contexts, right, wrong = seen["questions"]
    assert (name, description, rating, right, wrong) == (goal.name, goal.description, 1200, [], [])
    assert target == 1200 + GENERATION_MARGIN
    assert frontier == goal.description
    assert [(c.state, c.metacognition) for c in contexts] == [("Beginner", "Curious")]
    assert seen["resources"][1:] == (
        goal.name,
        goal.description,
        "Beginner Curious",
        [],
        Language.ENGLISH,
    )
    bank = await QuestionRepository(test_db).list_bank_history(goal.id)
    assert sorted(h.question.text for h in bank) == ["Q0", "Q1"]


@pytest.mark.asyncio
async def test_a_later_run_reviews_the_context_and_buys_nothing_for_what_went_wrong(
    test_db, test_user, goal_factory, question_factory, answer_factory, exchange_factory
):
    """History exists, so the same entry point reviews instead of introducing -
    and the question he missed is the bank already holding tomorrow (#135), so
    the night stops after the review"""
    goal = await goal_factory(test_user)
    await onboarded(test_db, goal)
    missed = await question_factory(goal, text="What is 'ciao'?")
    await answer_factory(missed, correct=False, answered_at=at(10))
    await exchange_factory(goal)
    await StudentContextRepository(test_db).create(
        StudentContext(student_id=test_user.id, state="Beginner", metacognition="Curious")
    )
    await test_db.commit()

    calls = []
    with chain_gemini(test_db, calls, reviewed=review(added=[("Improving", "Doubtful")])):
        await run_student_chain(str(test_user.id))

    assert [name for name, _ in calls] == ["review", "resources"]
    _, standing, results, chats, _ = dict(calls)["review"]
    assert [(c.state, c.metacognition) for c in standing] == [("Beginner", "Curious")]
    assert [(r["question"], r["is_correct"]) for r in results] == [("What is 'ciao'?", False)]
    assert [c["prompt"] for c in chats] == ["q0"]


@pytest.mark.asyncio
async def test_the_resource_search_is_told_which_links_the_goal_already_has(
    test_db, test_user, goal_factory
):
    """A second run is asked for something new, and stores only what is new"""
    goal = await goal_factory(test_user)
    await onboarded(test_db, goal)
    held = resource(goal.id, "https://held.dev/a")
    await ResourceRepository(test_db).create(held)
    await test_db.commit()

    calls = []
    proposed = [resource(goal.id, "https://held.dev/a"), resource(goal.id, "https://new.dev/b")]
    with chain_gemini(test_db, calls, found=proposed):
        assert (await run_student_chain(str(test_user.id)))[2] == 1

    assert dict(calls)["resources"][4] == ["https://held.dev/a"]
    links = sorted(r.link for r in await ResourceRepository(test_db).list_by_goal(goal.id))
    assert links == ["https://held.dev/a", "https://new.dev/b"]


@pytest.mark.asyncio
async def test_resources_never_run_without_a_context(test_db, test_user, goal_factory):
    """'You cannot have resources without memory' - no context, no search"""
    await goal_factory(test_user)

    calls = []
    with chain_gemini(test_db, calls):
        assert await run_resources_step(test_db, str(test_user.id)) == 0

    assert calls == []


@pytest.mark.asyncio
async def test_the_caller_can_ask_for_a_chain_without_resources(test_db, test_user, goal_factory):
    """What the nightly run does six nights a week (#89): resources are weekly"""
    goal = await goal_factory(test_user)
    await onboarded(test_db, goal)

    calls = []
    with chain_gemini(test_db, calls, found=[resource(goal.id, "https://good.dev/a")]):
        assert await run_student_chain(str(test_user.id), with_resources=False) == (True, 2, 0)

    assert [name for name, _ in calls] == ["context", "questions"]
    assert await ResourceRepository(test_db).list_by_goal(goal.id) == []


@pytest.mark.asyncio
async def test_a_failed_step_keeps_what_the_steps_before_it_wrote(test_db, test_user, goal_factory):
    """Questions blow up: the context stays committed, resources never run"""
    goal = await goal_factory(test_user)
    await onboarded(test_db, goal)

    calls = []
    with chain_gemini(test_db, calls, questions=RuntimeError("quota")):
        with pytest.raises(RuntimeError):
            await run_student_chain(str(test_user.id))

    assert [name for name, _ in calls] == ["context", "questions"]
    assert len(await StudentContextRepository(test_db).list_valid(test_user.id)) == 1
    assert await QuestionRepository(test_db).list_bank_history(goal.id) == []
    assert await ResourceRepository(test_db).list_by_goal(goal.id) == []


@pytest.mark.asyncio
async def test_the_kickoff_never_raises_into_goal_creation(test_db, test_user, goal_factory):
    """Fire-and-forget: the failure is logged, the request that fired it is long gone"""
    goal = await goal_factory(test_user)
    await onboarded(test_db, goal)

    calls = []
    with chain_gemini(test_db, calls, questions=RuntimeError("quota")):
        kickoff_student_chain(str(test_user.id))
        await asyncio.gather(*student_chain._running)

    assert len(await StudentContextRepository(test_db).list_valid(test_user.id)) == 1


@pytest.mark.asyncio
async def test_two_goals_get_one_context_and_a_bank_each(test_db, test_user, goal_factory):
    """#87: the context is the student's, written once from every goal they have.
    The steps under it are per goal, so each bank is generated on its own."""
    law = await goal_factory(test_user, name="Law", description="Roman law.")
    history = await goal_factory(test_user, name="History", description="The 1800s.", active=True)
    await onboarded(test_db, history)

    calls = []
    with chain_gemini(test_db, calls):
        assert await run_student_chain(str(test_user.id)) == (True, 4, 0)

    assert [name for name, _ in calls] == [
        "context",
        "questions",
        "questions",
        "resources",
        "resources",
    ]
    seen = sorted((g.name, g.description) for g in dict(calls)["context"][0])
    assert seen == [(history.name, history.description), (law.name, law.description)]
    stored = await StudentContextRepository(test_db).list_valid(test_user.id)
    assert [(c.state, c.metacognition) for c in stored] == [("Beginner", "Curious")]
    for goal in (law, history):
        bank = await QuestionRepository(test_db).list_bank_history(goal.id)
        assert sorted(h.question.text for h in bank) == ["Q0", "Q1"]


@pytest.mark.asyncio
async def test_a_student_with_no_goals_spends_nothing(test_db, test_user):
    """Nothing to write about, nothing to generate for: no Gemini call at all"""
    calls = []
    with chain_gemini(test_db, calls):
        assert await run_student_chain(str(test_user.id)) == (False, 0, 0)

    assert calls == []


@pytest.mark.asyncio
async def test_the_batch_goal_creation_fires_never_reads_the_standard_questions(
    test_db, test_user, goal_factory
):
    """#132: the student answers them while this run is in flight, so they are
    memory for the generations after it, never an input this one waits for.

    The guarantee is the cutoff `POST /goals` passes, not the speed of a human:
    here he answers *before* the run starts and it still does not see them.
    """
    goal = await goal_factory(test_user)
    await onboarded(test_db, goal)
    as_of = await answered_the_standard_questions(test_db, goal)

    calls = []
    with chain_gemini(test_db, calls):
        await run_student_chain(str(test_user.id), onboarding_as_of=as_of)

    assert dict(calls)["context"][2] == [PROMPT_PAIR, *ANSWERS]


@pytest.mark.asyncio
async def test_the_generation_after_it_does_read_them(test_db, test_user, goal_factory):
    """Same chain, same student, no cutoff: every run but goal creation's own"""
    goal = await goal_factory(test_user)
    await onboarded(test_db, goal)
    await answered_the_standard_questions(test_db, goal)

    calls = []
    with chain_gemini(test_db, calls):
        await run_student_chain(str(test_user.id))

    assert dict(calls)["context"][2] == [PROMPT_PAIR, *ANSWERS, STANDARD_PAIR]


@pytest.mark.asyncio
async def test_a_review_is_told_what_the_student_said_about_himself(
    test_db, test_user, goal_factory, question_factory, answer_factory
):
    """The night after his first lesson is a review, not a first impression, so
    the standard answers would be dead data if only the first impression read
    them (#132). Facts about a person do not go stale; a reading of him does."""
    goal = await goal_factory(test_user)
    await onboarded(test_db, goal)
    await answered_the_standard_questions(test_db, goal)
    missed = await question_factory(goal, text="What is 'ciao'?")
    await answer_factory(missed, correct=False, answered_at=at(10))
    await StudentContextRepository(test_db).create(
        StudentContext(student_id=test_user.id, state="Beginner", metacognition="Curious")
    )
    await test_db.commit()

    calls = []
    with chain_gemini(test_db, calls):
        await run_student_chain(str(test_user.id))

    assert dict(calls)["review"][4] == [PROMPT_PAIR, *ANSWERS, STANDARD_PAIR]
