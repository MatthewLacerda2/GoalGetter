"""The embedding backfill: what it sends, what it refuses to send (#96).

The evidence here is `calls` - every batch handed to Gemini, in order. Most of
these tests are about a call that must *not* happen: a row that already has its
vector, a row whose text is empty, a night with nothing to do. Asserting the
rows afterwards would not catch any of them, because a job that re-embeds
everything every night leaves exactly the same database behind as one that
embeds only what is null. It just costs money.

Every moment is written in UTC and converted, never built in the ambient zone -
the same discipline as the clock's own tests (#92). Midnight in
America/Sao_Paulo is 03:00 UTC; 03:00 there is 06:00 UTC.
"""

from contextlib import contextmanager
from datetime import UTC, datetime, timedelta
from unittest.mock import patch

import numpy as np
import pytest

from backend.core import clock
from backend.models.resource import Resource, StudyResourceType
from backend.models.student_context import StudentContext
from backend.services.jobs.embeddings import run_embeddings
from backend.tests.fixtures.jobs import Session
from backend.tools import nightly_run
from backend.utils.envs import NUM_DIMENSIONS

EMBEDDINGS = "backend.services.jobs.embeddings"


def utc(*args) -> datetime:
    return datetime(*args, tzinfo=UTC)


def a_vector(text: str) -> np.ndarray:
    """A stand-in vector. Its first value is the text's length, so a test can
    tell which text a stored embedding came from."""
    vector = np.zeros(NUM_DIMENSIONS, dtype=np.float32)
    vector[0] = len(text)
    return vector


@contextmanager
def gemini(test_db, calls, error=None):
    """The backfill with its one Gemini call recorded, and the session it opens
    for itself replaced by the test's - it is an entry point, not a service.

    `error` is a plain RuntimeError in these tests on purpose: the retry policy
    does not repeat what cannot recover, so a failing batch fails once instead
    of spending fourteen seconds of backoff in the suite.
    """

    def embed(texts):
        calls.append(list(texts))
        if error is not None:
            raise error
        return [a_vector(text) for text in texts]

    with (
        patch(EMBEDDINGS + ".get_gemini_embeddings_batch", embed),
        patch(EMBEDDINGS + ".AsyncSessionLocal", return_value=Session(test_db)),
    ):
        yield


def sent(calls) -> set[str]:
    """Every text that reached Gemini, whatever batch it rode in."""
    return {text for call in calls for text in call}


def tally(tallies, column: str):
    return next(item for item in tallies if item.column == column)


@pytest.mark.asyncio
async def test_a_row_that_already_has_its_vector_is_not_sent(
    test_db, test_user, goal_factory, question_factory
):
    """Null is the queue: an embedded question is not re-embedded, ever"""
    goal = await goal_factory(test_user, description=None)
    done = await question_factory(goal, text="already embedded")
    done.question_embedding = a_vector("already embedded")
    await question_factory(goal, text="still null")
    await test_db.commit()

    calls = []
    with gemini(test_db, calls):
        tallies = await run_embeddings()

    assert sent(calls) == {"still null"}
    assert tally(tallies, "lesson_questions.question_embedding").queued == 1


@pytest.mark.asyncio
async def test_half_an_embedded_row_only_sends_the_half_that_is_null(
    test_db, test_user, goal_factory, exchange_factory
):
    """Two of the seven columns share a table, and the row is read once for both

    The query can only say "this row has *a* null"; which of the two it is, is
    the column's own question. A row whose prompt is embedded and whose reply
    is not must cost one call, not two.
    """
    goal = await goal_factory(test_user, description=None)
    (exchange,) = await exchange_factory(goal)
    exchange.prompt_embedding = a_vector("q0")
    await test_db.commit()

    calls = []
    with gemini(test_db, calls):
        tallies = await run_embeddings()

    assert sent(calls) == {"a0 b0"}
    assert tally(tallies, "chat_messages.prompt_embedding").queued == 0
    assert tally(tallies, "chat_messages.tutor_response_embedding").filled == 1


@pytest.mark.asyncio
async def test_a_night_with_nothing_null_makes_no_gemini_call_at_all(
    test_db, test_user, goal_factory, question_factory
):
    """Not a cheaper run, no run: the no-op costs zero calls"""
    goal = await goal_factory(test_user, description="Hold a chat.")
    goal.description_embedding = a_vector("Hold a chat.")
    question = await question_factory(goal, text="Q?")
    question.question_embedding = a_vector("Q?")
    await test_db.commit()

    calls = []
    with gemini(test_db, calls):
        tallies = await run_embeddings()

    assert calls == []
    assert sum(item.filled for item in tallies) == 0


@pytest.mark.asyncio
async def test_a_failed_batch_leaves_the_rows_null_for_the_next_run(
    test_db, test_user, goal_factory, question_factory
):
    """The failure is not recorded anywhere, because the null already is"""
    goal = await goal_factory(test_user, description=None)
    question = await question_factory(goal, text="unlucky")
    await test_db.commit()

    calls = []
    with gemini(test_db, calls, error=RuntimeError("quota")):
        tallies = await run_embeddings()

    assert question.question_embedding is None
    assert tally(tallies, "lesson_questions.question_embedding").left == 1

    with gemini(test_db, calls):
        await run_embeddings()

    assert question.question_embedding is not None


@pytest.mark.asyncio
async def test_an_empty_text_is_never_sent_and_stays_null(test_db, test_user, goal_factory):
    """A goal with no description has nothing to say; a zero vector would lie"""
    goal = await goal_factory(test_user, description="   ")
    await test_db.commit()

    calls = []
    with gemini(test_db, calls):
        tallies = await run_embeddings()

    assert calls == []
    assert goal.description_embedding is None
    assert tally(tallies, "goals.description_embedding").left == 1


@pytest.mark.asyncio
async def test_every_one_of_the_seven_columns_is_filled(
    test_db, test_user, goal_factory, question_factory, exchange_factory
):
    """Five tables, seven columns, one run"""
    goal = await goal_factory(test_user, description="Hold a chat.")
    question = await question_factory(goal, text="Q?")
    (exchange,) = await exchange_factory(goal)
    resource = Resource(
        goal_id=goal.id,
        resource_type=StudyResourceType.webpage,
        name="Guide",
        description="A guide",
        language="en",
        link="https://good.dev/a",
    )
    context = StudentContext(student_id=test_user.id, state="Beginner", metacognition="Curious")
    test_db.add_all([resource, context])
    await test_db.commit()

    with gemini(test_db, []):
        tallies = await run_embeddings()

    assert sum(item.filled for item in tallies) == 7
    assert [item.column for item in tallies] == [
        "chat_messages.prompt_embedding",
        "chat_messages.tutor_response_embedding",
        "goals.description_embedding",
        "resources.description_embedding",
        "lesson_questions.question_embedding",
        "student_contexts.state_embedding",
        "student_contexts.metacognition_embedding",
    ]
    assert all(
        getattr(row, attribute) is not None
        for row, attribute in (
            (exchange, "prompt_embedding"),
            (exchange, "tutor_response_embedding"),
            (goal, "description_embedding"),
            (resource, "description_embedding"),
            (question, "question_embedding"),
            (context, "state_embedding"),
            (context, "metacognition_embedding"),
        )
    )


@pytest.mark.asyncio
async def test_a_tutor_reply_is_embedded_as_one_text_not_as_its_bubbles(
    test_db, test_user, goal_factory, exchange_factory
):
    """The reply is stored as the bubbles the screen draws; it means one thing"""
    goal = await goal_factory(test_user, description=None)
    await exchange_factory(goal)
    await test_db.commit()

    calls = []
    with gemini(test_db, calls):
        await run_embeddings()

    assert sent(calls) == {"q0", "a0 b0"}


def test_the_backfill_fires_at_midnight_three_hours_before_the_chain():
    """The clearance is the point: the cheap job is done before the chain spends"""
    evening = utc(2026, 9, 23, 20)  # 17:00 Brasilia

    backfill = clock.next_embedding_run(evening)
    chain = clock.next_nightly_run(evening)

    assert (backfill, chain) == (utc(2026, 9, 24, 3), utc(2026, 9, 24, 6))
    assert chain - backfill == timedelta(hours=clock.NIGHTLY_RUN_HOUR - clock.EMBEDDING_RUN_HOUR)


@pytest.mark.asyncio
async def test_the_runner_waits_for_whichever_hour_comes_first():
    """One process, one loop, one job at a time - never the two at once"""
    slept = []

    async def sleep(seconds):
        slept.append(seconds)

    async def picked(at):
        with (
            patch("backend.core.clock.now", lambda: at),
            patch("backend.tools.nightly_run.asyncio.sleep", sleep),
        ):
            name, _ = await nightly_run.wait_for_the_next_job()
        return name

    assert await picked(utc(2026, 9, 23, 20)) == "embedding backfill"  # 17:00 Brasilia
    assert await picked(utc(2026, 9, 24, 4)) == "nightly run"  # 01:00 Brasilia
    assert slept == [25200.0, 7200.0]
