"""The embedding backfill: every null vector, in batch, at midnight (#96).

**Null is the queue.** There is no state anywhere saying what has been embedded
and what has not - the column itself says it. A row is embedded because its
vector is null, and a row that failed is still null, so the next night picks it
up without anybody having written down that it failed. That is also why the job
is safe to run by hand at any hour: it can only ever do work nobody has done.

**Nothing is ever blocked by a missing embedding.** Every reader of these seven
columns works without one today and must keep doing so - a night that was
skipped, a machine that was asleep, a quota that ran out are all normal, and
none of them may cost a student a lesson. This job is the only writer and it
owns none of the readers.

**In batch, because that is what makes it cheap.** The queue for one column is
chunked into `EMBEDDING_BATCH_SIZE` texts, and each chunk is a single billed
call (`get_gemini_embeddings_batch`).

**A failed chunk is logged and the run carries on with the next one.** Not the
chain's rule (`student_chain.py` stops at the first failure) and deliberately
so: the chain's steps feed each other, these chunks do not, and a single row
Gemini will never accept - a text too long, say - would otherwise wedge every
column behind it, every night, for good. `run_gemini_background` has already
spent its retry budget by the time a chunk fails here, so carrying on is not a
hammer loop; it is the difference between losing one chunk and losing the queue.

**An empty text is skipped, not embedded.** A goal with no description, a chat
turn with no reply: there is nothing to say about them, the API rejects empty
content, and a zero vector would be a lie that similarity search believes. The
row stays null and costs nothing - it is counted as "left", and it will be
looked at again tomorrow for as long as it stays empty, which is free.
"""

import logging
from dataclasses import dataclass

from backend.core.database import AsyncSessionLocal
from backend.services.jobs.embedding_columns import SOURCES, EmbeddingColumn, EmbeddingSource
from backend.utils.gemini.gemini_configs import get_gemini_embeddings_batch
from backend.utils.gemini.gemini_guard import run_gemini_background

logger = logging.getLogger(__name__)

# How many texts ride in one call. Gemini takes a list per request; a hundred
# keeps a single failure cheap and the request well inside any payload limit.
EMBEDDING_BATCH_SIZE = 100

# How many rows one run reads per table. The tables only grow, and an unbounded
# read of every chat message ever written is how a nightly job eventually dies
# of memory. What does not fit waits for tomorrow - the queue is the column.
ROWS_PER_TABLE = 2000


@dataclass
class Tally:
    """What one column's pass did, which is what the run has to be able to say."""

    column: str
    queued: int = 0
    filled: int = 0

    @property
    def left(self) -> int:
        """Rows still null when the pass ended: failed chunks, empty texts, and
        anything beyond the cap this run never read."""
        return self.queued - self.filled


async def run_embeddings() -> list[Tally]:
    """Fill every null embedding the cap lets this run see. One tally per column.

    Never raises for a Gemini failure: a lost chunk is a lost chunk, and the
    row it belonged to is still null, which is all the memory this job has.
    """
    tallies: list[Tally] = []
    async with AsyncSessionLocal() as session:
        for source in SOURCES:
            rows = await source.repository(session).list_missing_embeddings(ROWS_PER_TABLE)
            logger.info("Embeddings: %s has %d row(s) with a null vector", source.table, len(rows))
            for column in source.columns:
                tallies.append(await _fill(session, source, column, rows))

    logger.info(
        "Embeddings finished: %d filled, %d left across %d column(s)",
        sum(tally.filled for tally in tallies),
        sum(tally.left for tally in tallies),
        len(tallies),
    )
    return tallies


async def _fill(session, source: EmbeddingSource, column: EmbeddingColumn, rows) -> Tally:
    """One column's pass over the rows already read for its table."""
    tally = Tally(f"{source.table}.{column.attribute}")
    pending = [row for row in rows if getattr(row, column.attribute) is None]
    tally.queued = len(pending)

    # The skip is the point: an empty text is never sent, so it costs nothing.
    work = [(row, (column.text(row) or "").strip()) for row in pending]
    work = [(row, text) for row, text in work if text]

    repository = source.repository(session)
    for start in range(0, len(work), EMBEDDING_BATCH_SIZE):
        chunk = work[start : start + EMBEDDING_BATCH_SIZE]
        tally.filled += await _embed_chunk(session, repository, column, chunk)

    logger.info(
        "Embeddings: %s - %d null, %d filled, %d left",
        tally.column,
        tally.queued,
        tally.filled,
        tally.left,
    )
    return tally


async def _embed_chunk(session, repository, column: EmbeddingColumn, chunk) -> int:
    """One billed call, then one commit. Returns how many rows it wrote.

    The commit is per chunk on purpose: what a chunk paid for is written before
    the next one is asked for, so a failure later in the run - or the process
    being stopped - never throws away a call that already succeeded. Nothing is
    ever left half-written to roll back: the rows are touched only after the
    call they belong to has answered.
    """
    try:
        vectors = await run_gemini_background(get_gemini_embeddings_batch, [t for _, t in chunk])
    except Exception:
        logger.exception(
            "Embeddings: a batch of %d for %s failed; those rows stay null for the next run",
            len(chunk),
            column.attribute,
        )
        return 0

    if len(vectors) != len(chunk):
        # One vector per text, in order, is the contract the whole batch rests
        # on. A short answer cannot be matched up, so none of it is written.
        logger.error(
            "Embeddings: %s asked for %d vectors and got %d; the batch is dropped",
            column.attribute,
            len(chunk),
            len(vectors),
        )
        return 0

    for (row, _), vector in zip(chunk, vectors, strict=True):
        setattr(row, column.attribute, vector)
        await repository.update(row)
    await session.commit()
    return len(chunk)
