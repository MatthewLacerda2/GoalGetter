import uuid

from sqlalchemy import select

from backend.models.frontier import Frontier
from backend.repositories.base import BaseRepository


class FrontierRepository(BaseRepository[Frontier]):
    """Where we are taking the student, per goal (#133). Append-only: the
    current frontier is the newest row, and the rows before it are the record
    of where he has been taken.

    So a definition is never rewritten - moving the target is a new row - and the
    only field anything updates is the null embedding the midnight backfill fills
    in (#96). There is no `delete` (it is a `BaseRepository`, not a
    `DeletableRepository`): deleting the goal takes its frontiers with it, which
    the database does on its own (ON DELETE CASCADE)."""

    model = Frontier

    async def current(self, goal_id: uuid.UUID) -> Frontier | None:
        """The goal's newest frontier - what we are teaching him today.

        `None` is unreachable for a goal created through `GoalRepository`,
        which writes the first frontier with the goal. It is still the return
        type: a query cannot promise what the schema does not, and a caller
        that reads it falls back to the goal's own description.
        """
        stmt = (
            select(Frontier)
            .where(Frontier.goal_id == goal_id)
            .order_by(Frontier.created_at.desc(), Frontier.id.desc())
            .limit(1)
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_by_goal(self, goal_id: uuid.UUID) -> list[Frontier]:
        """The whole history, oldest first: where the student started and every
        threshold he has been moved to since."""
        stmt = (
            select(Frontier)
            .where(Frontier.goal_id == goal_id)
            .order_by(Frontier.created_at, Frontier.id)
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def list_missing_embeddings(self, limit: int) -> list[Frontier]:
        """Frontiers whose definition embedding is still null, oldest first (#96).

        The old rows are in the queue like the current one: the history is what
        a later similarity question would be asked about.
        """
        stmt = (
            select(Frontier)
            .where(Frontier.definition_embedding.is_(None))
            .order_by(Frontier.created_at, Frontier.id)
            .limit(limit)
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())
