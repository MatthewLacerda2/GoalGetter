"""Background work kicked off when a goal is created.

Both jobs are fire-and-forget: the goal-creation response returns immediately and
the introduction screens buy time while these run. They are also meant to run on
their own schedule later (resources: on a significant skill jump or monthly;
lessons: a daily check that skips users who did no lessons).

Nothing here is allowed to fail the request that started it, so every job is
wrapped and its errors are logged rather than raised.
"""

import asyncio
import logging

from backend.core.database import AsyncSessionLocal
from backend.models.lesson_question import LessonQuestion
from backend.models.student_context import StudentContext
from backend.repositories.goal_repository import GoalRepository
from backend.repositories.lesson_question_repository import LessonQuestionRepository
from backend.repositories.resource_repository import ResourceRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.gemini.lesson import generate_lesson_questions
from backend.services.gemini.resources.search_resources import search_resources
from backend.services.gemini.student_context import gemini_generate_student_context
from backend.services.resources.link_validation import validate_resources
from backend.utils.gemini.gemini_guard import run_gemini_background

logger = logging.getLogger(__name__)


async def scrape_resources(goal_id: str) -> int:
    """Find, verify and store study resources for a goal. Returns how many stuck."""
    async with AsyncSessionLocal() as session:
        goal = await GoalRepository(session).get_by_id(goal_id)
        if goal is None:
            logger.warning("Resource scraping: goal %s no longer exists", goal_id)
            return 0

        # The Gemini client is synchronous and this is a slow, grounded search,
        # so keep it off the event loop. Nobody is waiting on this job, so it
        # retries on the background budget (backend/utils/gemini/gemini_retry.py).
        recommended = await run_gemini_background(
            search_resources, goal_id, goal.name, goal.description
        )
        logger.info("Gemini recommended %d resources for goal %s", len(recommended), goal_id)

        verified = await validate_resources(recommended)

        repository = ResourceRepository(session)
        already_stored = await repository.existing_links(goal_id, [r.link for r in verified])
        fresh = [r for r in verified if r.link not in already_stored]

        await repository.create_many(fresh)
        await session.commit()

    logger.info("Stored %d resources for goal %s", len(fresh), goal_id)
    return len(fresh)


async def generate_lessons(goal_id: str, prompt: str, answers: list[tuple[str, str]]) -> int:
    """Build the goal's first lesson bank from the onboarding. Returns how many
    questions were stored.

    First the student context (the app's first impression of the learner, from
    the onboarding prompt and answers), then questions generated from it. The
    context is committed on its own: it is worth keeping even if question
    generation fails. The nightly regeneration (#63) is not this job.
    """
    async with AsyncSessionLocal() as session:
        goal = await GoalRepository(session).get_by_id(goal_id)
        if goal is None:
            logger.warning("Lessons generation: goal %s no longer exists", goal_id)
            return 0

        context = await run_gemini_background(
            gemini_generate_student_context, goal.name, goal.description, prompt, answers
        )
        await StudentContextRepository(session).create(
            StudentContext(
                student_id=goal.student_id,
                goal_id=goal.id,
                state=context.state,
                metacognition=context.metacognition,
            )
        )
        await session.commit()

        generated = await run_gemini_background(
            generate_lesson_questions,
            goal.name,
            goal.description,
            goal.rating,
            context.state,
            context.metacognition,
        )
        # A question whose correct index is out of range would fail the table's
        # check constraint and take the whole batch with it: drop just that one.
        questions = [
            LessonQuestion(
                goal_id=goal.id,
                question=q.question,
                option_a=q.option_a,
                option_b=q.option_b,
                option_c=q.option_c,
                option_d=q.option_d,
                correct_option_index=q.correct_option_index,
            )
            for q in generated.questions
            if 0 <= q.correct_option_index <= 3
        ]
        await LessonQuestionRepository(session).create_many(questions)
        await session.commit()

    logger.info("Stored %d lesson questions for goal %s", len(questions), goal_id)
    return len(questions)


async def _run_safely(name: str, coroutine) -> None:
    try:
        await coroutine
    except Exception:
        logger.exception("Background job %s failed", name)


def _spawn(name: str, coroutine) -> None:
    """Schedule a job on the running loop, keeping a reference so it is not
    garbage-collected mid-flight."""
    task = asyncio.create_task(_run_safely(name, coroutine))
    _running.add(task)
    task.add_done_callback(_running.discard)


_running: set[asyncio.Task] = set()


def kickoff_resource_scraping(goal_id: str) -> None:
    _spawn("resource scraping", scrape_resources(goal_id))


def kickoff_lessons_generation(goal_id: str, prompt: str, answers: list[tuple[str, str]]) -> None:
    _spawn("lessons generation", generate_lessons(goal_id, prompt, answers))
