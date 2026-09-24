"""One chain per student: context, then questions, then resources (#88).

**One entry point.** `run_student_chain(student_id)` is what goal creation
fires and what the nightly run (#89) will call for each student it does not
skip. There is no first-run variant: the steps read the database, and a student
who has done nothing yet simply has nothing for them to find.

**In order, never in parallel.** Gemini is called one at a time - three jobs
racing each other is how we hit a rate limit and how the resource search ended
up reading a context that another job was still writing. Each step also *needs*
what the one before it wrote: questions read the context, and resources are not
allowed to run without one.

**Each step commits its own work, and the chain stops at the first failure.**
What has been written stays written - a context that cost a premium call is not
thrown away because the question bank failed afterwards. The steps that had not
run yet do not run: a Gemini failure is usually the rate limit or the quota,
and firing the next two calls straight at it is how one failed step becomes
three. The next run picks up where this one stopped, and the nightly run is
what makes "the next run" a certainty rather than a hope.
"""

import asyncio
import logging

from backend.core.database import AsyncSessionLocal
from backend.services.jobs.steps.context import run_context_step
from backend.services.jobs.steps.questions import run_questions_step
from backend.services.jobs.steps.resources import run_resources_step

logger = logging.getLogger(__name__)


async def run_student_chain(student_id: str) -> tuple[bool, int, int]:
    """Run the whole chain for one student: what each step did, in order.

    Raises whatever a step raised, so the caller decides what a failure means:
    goal creation logs it and moves on, the nightly run (#89) logs it and moves
    on to the next student.
    """
    async with AsyncSessionLocal() as session:
        wrote_context = await run_context_step(session, student_id)
        questions = await run_questions_step(session, student_id)
        resources = await run_resources_step(session, student_id)

    logger.info(
        "Chain for student %s: context %s, %d questions, %d resources",
        student_id,
        "written" if wrote_context else "skipped",
        questions,
        resources,
    )
    return wrote_context, questions, resources


async def _run_safely(student_id: str) -> None:
    try:
        await run_student_chain(student_id)
    except Exception:
        logger.exception("Chain for student %s failed", student_id)


def kickoff_student_chain(student_id: str) -> None:
    """Fire the chain on the running loop and return: goal creation answers
    immediately and the introduction screens buy the time.

    The task is kept in a set so it is not garbage-collected mid-flight.
    """
    task = asyncio.create_task(_run_safely(student_id))
    _running.add(task)
    task.add_done_callback(_running.discard)


_running: set[asyncio.Task] = set()
