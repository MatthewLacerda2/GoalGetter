"""The nightly run: who gets a chain tonight, and who is skipped (#89).

**The rules, in the user's terms (2026-09-23).** The most important thing is
that the student has lessons to do every day. Generation runs at night, when
Google's servers are quiet and nobody is studying - by then the student either
did today's lesson or was not going to. A student who did no lesson that day is
skipped *entirely*: no context, no questions, no call at all. A day counts
because he answered at least one question in it (#131) - there is no lesson
row. Chat activity does not count; only answers do. Resources are rare - Monday only, and only for
a student who studied in the past week.

**"That day" is not the calendar day.** The run fires at 03:00, and reading the
calendar date there would skip everyone who studied the evening before, which
is everyone. The day the run closes out is the 24 hours behind it - see
`clock.previous_nightly_run`.

**One student at a time.** Gemini is called serially for the same reason the
chain is a chain: the rate limit must never be the reason a night fails. And a
student whose chain raises is logged and left behind - the next student still
runs, because one quota error must not cost everybody their questions.

What triggers this is `backend/tools/nightly_run.py`; this module only decides
and executes, so a test can pin the decision without a clock or a scheduler.
"""

import logging
from dataclasses import dataclass
from datetime import datetime

from backend.core import clock
from backend.core.database import AsyncSessionLocal
from backend.repositories.student_answer_repository import StudentAnswerRepository
from backend.repositories.student_repository import StudentRepository
from backend.services.jobs.student_chain import run_student_chain

logger = logging.getLogger(__name__)

# Monday, as `datetime.weekday()` numbers the days.
RESOURCE_WEEKDAY = 0


@dataclass(frozen=True)
class Decision:
    """What the run decided about one student, and the sentence that says why.

    The reason is not decoration: running the job by hand for one student is
    how its behaviour is watched (#89), and what there is to watch is exactly
    these sentences.
    """

    run: bool
    with_resources: bool
    reason: str


def decide(last_answer: datetime | None, at: datetime) -> Decision:
    """Everything the nightly run decides about one student, from one moment.

    Pure on purpose: the gate is a rule about days and weekdays, and a rule
    like that is worth pinning in a test that needs neither a database nor a
    scheduler to state it.
    """
    since = clock.previous_nightly_run(at)
    if last_answer is None:
        return Decision(False, False, "skipped: no question has ever been answered")

    last = clock.as_utc(last_answer)
    if last < since:
        return Decision(
            False, False, f"skipped: last answer {last:%Y-%m-%d %H:%M}Z is before {since:%H:%M}Z"
        )
    if clock.app_local(at).weekday() != RESOURCE_WEEKDAY:
        return Decision(True, False, "context and questions: a question was answered today")

    # The rule also says resources need study in the last seven days, and
    # there is no test of it here because reaching this line already proves it:
    # the student studied within the last 24 hours or they were skipped above.
    # Writing the week out as a second comparison would be a branch no input
    # can take - a rule stated twice, enforced once.
    return Decision(True, True, "context, questions and resources: Monday with a lesson this week")


async def run_for_student(student_id: str, at: datetime | None = None) -> bool:
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
        ran += await run_for_student(str(student_id), at)

    logger.info("Nightly run finished: %d of %d students had a chain run", ran, len(student_ids))
    return len(student_ids), ran
