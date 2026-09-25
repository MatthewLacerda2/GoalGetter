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
from datetime import datetime

from backend.core.database import AsyncSessionLocal
from backend.services.jobs.steps.context import run_context_step
from backend.services.jobs.steps.questions import run_questions_step
from backend.services.jobs.steps.resources import run_resources_step

logger = logging.getLogger(__name__)


async def run_student_chain(
    student_id: str,
    with_resources: bool = True,
    onboarding_as_of: datetime | None = None,
) -> tuple[bool, int, int]:
    """Run the whole chain for one student: what each step did, in order.

    `with_resources` is the one thing a caller decides about *what runs*,
    because resources are the one step that is not wanted every time: the
    nightly run buys them once a week (#89), goal creation wants them for a
    goal that has none. Everything else a step needs it reads for itself.

    `onboarding_as_of` decides nothing about what runs; it pins *how far* the
    onboarding is read. Goal creation passes the instant it finished writing,
    so this run - the first batch - cannot see the standard questions the
    student starts answering the moment it returns (#132). Every other caller
    passes nothing and the whole onboarding is read, which is what makes the
    generation after the first the one those answers reach.

    Raises whatever a step raised, so the caller decides what a failure means:
    goal creation logs it and moves on, the nightly run logs it and moves on to
    the next student.
    """
    async with AsyncSessionLocal() as session:
        wrote_context = await run_context_step(session, student_id, onboarding_as_of)
        questions = await run_questions_step(session, student_id)
        resources = await run_resources_step(session, student_id) if with_resources else 0

    logger.info(
        "Chain for student %s: context %s, %d questions, %d resources%s",
        student_id,
        "written" if wrote_context else "unchanged",
        questions,
        resources,
        "" if with_resources else " (resources not asked for)",
    )
    return wrote_context, questions, resources


async def _run_safely(student_id: str, onboarding_as_of: datetime | None) -> None:
    try:
        await run_student_chain(student_id, onboarding_as_of=onboarding_as_of)
    except Exception:
        logger.exception("Chain for student %s failed", student_id)


def kickoff_student_chain(student_id: str, onboarding_as_of: datetime | None = None) -> None:
    """Fire the chain on the running loop and return: goal creation answers
    immediately and the standard questions (#132) buy the time.

    The task is kept in a set so it is not garbage-collected mid-flight.
    """
    task = asyncio.create_task(_run_safely(student_id, onboarding_as_of))
    _running.add(task)
    task.add_done_callback(_running.discard)


_running: set[asyncio.Task] = set()
