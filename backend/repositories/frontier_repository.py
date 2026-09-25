from sqlalchemy import select

from backend.models.frontier import Frontier
from backend.repositories.base import BaseRepository


class FrontierRepository(BaseRepository[Frontier]):
    """Where we are taking the student, per goal (#133). Append-only: the
    current frontier is the newest row, and the rows before it are the record
    of where he has been taken."""

    async def create(self, entity: Frontier) -> Frontier:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity

    async def get_by_id(self, entity_id: str) -> Frontier | None:
        stmt = select(Frontier).where(Frontier.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def current(self, goal_id) -> Frontier | None:
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

    async def list_by_goal(self, goal_id) -> list[Frontier]:
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

    async def update(self, entity: Frontier) -> Frontier:
        """Flush a row. The definition is never rewritten - moving the target
        is a new row (#133), and the old one is the record of where the student
        has been. The only field anything updates is the null embedding the
        midnight backfill fills in (#96)."""
        await self.db.flush()
        return entity

    async def delete(self, entity_id: str) -> bool:
        """A frontier is never deleted. Deleting the goal takes its frontiers
        with it, which the database does on its own (ON DELETE CASCADE)."""
        raise NotImplementedError("A frontier is never deleted")
