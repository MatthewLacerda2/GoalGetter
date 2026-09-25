"""Where the nightly run moves the target (#133).

A goal has no finish line. `goals.description` is what the student asked for on
day one and never changes; the frontier is the threshold we are teaching him at
today, and when he has learned everything the goal holds the app takes him
outward - circuits to robotics - rather than stopping.

**The move rides on the context review, not on a job of its own.** That call is
already reading every goal, the student's recent answers and his recent chats
with the tutor, which is exactly the evidence a move needs. What he asks the
tutor is in the prompt because *"no que ele pareça demonstrar interesse"* -
interest is evidence about where to take him, and it costs nothing here: the
chats were already there for the reading of the student.

**A night that changes nothing writes no row.** An unchanged frontier is the
normal case, as an unchanged context already is.

**A frontier that lands far from the goal is refused, not written.** The move
is meant to be the same goal seen further on; a definition whose embedding sits
far from the goal's own is the app wandering off, and the row that would record
it is the one thing we cannot take back - frontiers are append-only, so a bad
row is permanent. Refusing costs the student nothing: he keeps studying the
frontier he is on, and tomorrow night may propose again.

The floor is deliberately low. It is there to catch a different subject, not to
keep the student where he started, and the whole point of the feature is that
the target travels. When the check cannot be made - the goal has no embedding
yet, or Gemini will not answer - the move is accepted and logged as unchecked:
nothing in this app is ever blocked by a missing embedding.
"""

import logging

import numpy as np

from backend.models.frontier import Frontier
from backend.repositories.frontier_repository import FrontierRepository
from backend.utils.gemini.gemini_configs import get_gemini_embeddings
from backend.utils.gemini.gemini_guard import run_gemini_background

logger = logging.getLogger(__name__)

# Cosine similarity a proposal must keep with the goal's own description.
# Related subjects sit well above this; an unrelated one does not.
MIN_SIMILARITY = 0.30


async def current_definitions(session, goals) -> list[str]:
    """What we are teaching the student today, one definition per goal, in the
    order the goals came in.

    A goal created through `GoalRepository` always has a frontier, so the
    fallback to the goal's own description is only ever reached by a row
    written before this existed.
    """
    repository = FrontierRepository(session)
    definitions = []
    for goal in goals:
        current = await repository.current(goal.id)
        definitions.append(current.definition if current else (goal.description or ""))
    return definitions


async def apply_frontier_moves(session, goals, definitions: list[str], moves) -> int:
    """Append the frontiers the review moved, and return how many rows were
    written. Zero is the normal night.

    An index the model invented, or repeated, is dropped rather than failing
    the run - the same tolerance the standing readings already have. So is a
    definition that only repeats the frontier the goal is already on: that is
    not a move, and an append-only table must not collect it.
    """
    repository = FrontierRepository(session)
    seen: set[int] = set()
    written = 0
    for move in moves:
        if not 0 <= move.index < len(goals) or move.index in seen:
            logger.info("Frontier step: ignoring a move on index %s", move.index)
            continue
        seen.add(move.index)
        definition = move.definition.strip()
        if not definition or definition == definitions[move.index].strip():
            logger.info("Frontier step: goal index %s has not moved", move.index)
            continue
        written += await _append(repository, goals[move.index], definition)
    return written


async def _append(repository: FrontierRepository, goal, definition: str) -> int:
    """Write one move, unless it is the app wandering off. Returns 1 or 0.

    The embedding is taken here rather than left to the midnight backfill
    because it is what the check reads. Having paid for it, the row keeps it:
    the backfill's queue is the null column, so a vector stored now is simply
    work it will not have to do.
    """
    embedding = await _embedding_of(definition)
    similarity = _similarity(goal.description_embedding, embedding)
    if similarity is not None and similarity < MIN_SIMILARITY:
        logger.warning(
            "Frontier step: refusing a frontier for goal %s, similarity %.2f to its own "
            "description is below %.2f - proposed: %s",
            goal.id,
            similarity,
            MIN_SIMILARITY,
            definition,
        )
        return 0
    if similarity is None:
        logger.info("Frontier step: goal %s moved unchecked, no embedding to compare", goal.id)

    await repository.create(
        Frontier(goal_id=goal.id, definition=definition, definition_embedding=embedding)
    )
    logger.info("Frontier step: goal %s moved on to: %s", goal.id, definition)
    return 1


async def _embedding_of(definition: str):
    """The proposal as a vector, or None if Gemini would not answer. A night
    that cannot embed still teaches; it just cannot check."""
    try:
        return await run_gemini_background(get_gemini_embeddings, definition)
    except Exception:
        logger.exception("Frontier step: could not embed a proposed frontier")
        return None


def _similarity(goal_embedding, proposed) -> float | None:
    """Cosine similarity between the goal's description and the proposal, or
    None when either side is missing - which is not a failure, only a night
    where there is nothing to compare."""
    if goal_embedding is None or proposed is None:
        return None
    left = np.asarray(goal_embedding, dtype=np.float32)
    right = np.asarray(proposed, dtype=np.float32)
    norms = float(np.linalg.norm(left) * np.linalg.norm(right))
    if norms == 0.0:
        return None
    return float(np.dot(left, right) / norms)
