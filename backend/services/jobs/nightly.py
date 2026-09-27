"""The nightly run: who gets a chain tonight, and who is skipped (#89).

**Who is served** is decided in `nightly_decision.py` - the rules, and why a
day is not the calendar day. It is its own module because it is arithmetic,
and arithmetic never reaches Gemini, not even through the chain this module
runs (the import contracts in backend/pyproject.toml).

**One student at a time.** Gemini is called serially for the same reason the
chain is a chain: the rate limit must never be the reason a night fails. And a
student whose chain raises is logged and left behind - the next student still
runs, because one quota error must not cost everybody their questions.

What triggers this is `backend/tools/nightly_run.py`; this module only asks
the decision and executes it, so a test can pin the decision without a clock or
a scheduler.
"""

import logging
import uuid
from datetime import datetime

from backend.core import clock
from backend.core.database import AsyncSessionLocal
from backend.repositories.student_answer_repository import StudentAnswerRepository
from backend.repositories.student_repository import StudentRepository
from backend.services.jobs.nightly_decision import decide
from backend.services.jobs.student_chain import run_student_chain

logger = logging.getLogger(__name__)


async def run_for_student(student_id: uuid.UUID, at: datetime | None = None) -> bool:
    """Decide for one student and, if the decision says so, run their chain.

    Returns whether the chain ran. Never raises: a chain that failed is this
    student's night lost, not the night.
    """
    at = at or clock.now()
    async with AsyncSessionLocal() as session:
        last_answer = await StudentAnswerRepository(session).last_answered_at(student_id)

    decision = decide(last_answer, at)
    logger.info("Nightly run, student %s: %s", student_id, decision.reason)
    if not decision.run:
        return False

    try:
        await run_student_chain(student_id, with_resources=decision.with_resources)
    except Exception:
        logger.exception("Nightly run: the chain for student %s failed", student_id)
        return False
    return True


async def run_nightly(at: datetime | None = None) -> tuple[int, int]:
    """The whole night: every student, one after another. Returns how many were
    looked at and how many were run."""
    at = at or clock.now()
    async with AsyncSessionLocal() as session:
        student_ids = await StudentRepository(session).list_ids()

    logger.info("Nightly run starting at %s for %d students", at.isoformat(), len(student_ids))
    ran = 0
    for student_id in student_ids:
        ran += await run_for_student(student_id, at)

    logger.info("Nightly run finished: %d of %d students had a chain run", ran, len(student_ids))
    return len(student_ids), ran
