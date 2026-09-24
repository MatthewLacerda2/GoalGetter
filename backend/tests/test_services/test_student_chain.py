"""The student chain: context, then questions, then resources (#88).

Every Gemini call is replaced by `recorder`, which appends the call to one
shared list before returning its canned answer. That list is the evidence: it
says not only that a call happened but *when*, which is the whole point of a
chain - a step that reads what the step before it wrote cannot be allowed to
run first, or at the same time.
"""

import asyncio
from contextlib import contextmanager
from unittest.mock import patch

import pytest

from backend.models.resource import Resource, StudyResourceType
from backend.models.student_context import StudentContext
from backend.repositories.lesson_question_repository import LessonQuestionRepository
from backend.repositories.onboarding_repository import OnboardingRepository
from backend.repositories.resource_repository import ResourceRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.gemini.lesson.schema import GeminiLessonQuestionsResponse, LessonQuestionItem
from backend.services.gemini.student_context.schema import GeminiStudentContextResponse
from backend.services.jobs import student_chain
from backend.services.jobs.steps.resources import run_resources_step
from backend.services.jobs.student_chain import kickoff_student_chain, run_student_chain
from backend.tests.fixtures.lessons import at

CONTEXT = "backend.services.jobs.steps.context"
QUESTIONS = "backend.services.jobs.steps.questions"
RESOURCES = "backend.services.jobs.steps.resources"
CHAIN = "backend.services.jobs.student_chain"

FIRST = GeminiStudentContextResponse(state="Beginner", metacognition="Curious", ai_model="m")
REVISED = GeminiStudentContextResponse(state="Improving", metacognition="Doubtful", ai_model="m")
ANSWERS = [("Experience?", "None")]
PROMPT_PAIR = ("What do you want to learn?", "I want Italian")


def generated(*correct_indexes):
    return GeminiLessonQuestionsResponse(
        questions=[
            LessonQuestionItem(
                question=f"Q{i}",
                option_a="a",
                option_b="b",
                option_c="c",
                option_d="d",
                correct_option_index=index,
            )
            for i, index in enumerate(correct_indexes)
        ]
    )


GENERATED = generated(0, 3, 4)


def resource(goal_id, link):
    return Resource(
        goal_id=str(goal_id),
        resource_type=StudyResourceType.webpage,
        name="Guide",
        description="A guide",
        language="en",
        link=link,
    )


def recorder(calls: list, name: str, result):
    """A stand-in for one Gemini call: record it, then answer (or blow up)."""

    def record(*args):
        calls.append((name, args))
        if isinstance(result, Exception):
            raise result
        return result

    return record


@contextmanager
def chain_gemini(test_db, calls, questions=GENERATED, found=()):
    """The chain with every Gemini call mocked and every call recorded."""
    with (
        patch(CONTEXT + ".gemini_generate_student_context", recorder(calls, "context", FIRST)),
        patch(
            CONTEXT + ".gemini_generate_periodic_student_context",
            recorder(calls, "revision", REVISED),
        ),
        patch(QUESTIONS + ".generate_lesson_questions", recorder(calls, "questions", questions)),
        patch(RESOURCES + ".search_resources", recorder(calls, "resources", list(found))),
        patch(RESOURCES + ".validate_resources", side_effect=lambda proposed: proposed),
        patch(CHAIN + ".AsyncSessionLocal", return_value=_Session(test_db)),
    ):
        yield


async def onboarded(test_db, goal, prompt="I want Italian", answers=ANSWERS):
    await OnboardingRepository(test_db).save_onboarding(goal.id, prompt, answers)
    await test_db.commit()


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
    name, description, rating, contexts, errors = seen["questions"]
    assert (name, description, rating, errors) == (goal.name, goal.description, 1200, [])
    assert [(c.state, c.metacognition) for c in contexts] == [("Beginner", "Curious")]
    assert seen["resources"][1:] == (goal.name, goal.description, "Beginner Curious", [])
    bank = await LessonQuestionRepository(test_db).list_bank_history(goal.id)
    assert sorted(h.question.question for h in bank) == ["Q0", "Q1"]


@pytest.mark.asyncio
async def test_a_later_run_revises_the_context_and_aims_at_what_went_wrong(
    test_db, test_user, goal_factory, question_factory, answer_factory, exchange_factory
):
    """History exists, so the same entry point revises instead of introducing"""
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
    with chain_gemini(test_db, calls):
        await run_student_chain(str(test_user.id))

    assert [name for name, _ in calls] == ["revision", "questions", "resources"]
    _, state, metacognition, results, chats = dict(calls)["revision"]
    assert (state, metacognition) == ("Beginner", "Curious")
    assert [(r["question"], r["is_correct"]) for r in results] == [("What is 'ciao'?", False)]
    assert [c["prompt"] for c in chats] == ["q0"]
    assert dict(calls)["questions"][4] == ["What is 'ciao'?"]


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
    assert await LessonQuestionRepository(test_db).list_bank_history(goal.id) == []
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
        bank = await LessonQuestionRepository(test_db).list_bank_history(goal.id)
        assert sorted(h.question.question for h in bank) == ["Q0", "Q1"]


@pytest.mark.asyncio
async def test_a_student_with_no_goals_spends_nothing(test_db, test_user):
    """Nothing to write about, nothing to generate for: no Gemini call at all"""
    calls = []
    with chain_gemini(test_db, calls):
        assert await run_student_chain(str(test_user.id)) == (False, 0, 0)

    assert calls == []


class _Session:
    """Hands the chain the test's session and keeps it open afterwards."""

    def __init__(self, session):
        self.session = session

    async def __aenter__(self):
        return self.session

    async def __aexit__(self, *exc):
        return False
