from sqlalchemy import delete as sql_delete
from sqlalchemy import select
from sqlalchemy import update as sql_update

from backend.core import clock
from backend.models.goal import Goal
from backend.repositories.base import BaseRepository


class GoalRepository(BaseRepository[Goal]):
    async def create(self, entity: Goal) -> Goal:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity

    async def get_by_id(self, entity_id: str) -> Goal | None:
        stmt = select(Goal).where(Goal.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_by_student(self, student_id) -> list[Goal]:
        """The student's goals, newest first."""
        stmt = select(Goal).where(Goal.student_id == student_id).order_by(Goal.created_at.desc())
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def set_rating(self, goal_id, rating: int) -> int:
        """Write the goal's rating, and return it.

        The rating is *replayed* from the whole answer history (#62), never
        incremented, so what is written is a fact about the history and not the
        result of a read-then-write: two lessons finishing at once can no longer
        lose a delta between them, and a rating that somehow drifted is repaired
        by the next submission rather than carried forever.

        `updated_at` is set here because a Core-style UPDATE does not fire the
        column's ORM `onupdate` (#72), and the goals list reads it as "last
        studied". The session's copy of the goal is synchronized ("fetch"), so a
        later flush cannot write a stale rating back over it.
        """
        stmt = (
            sql_update(Goal)
            .where(Goal.id == goal_id)
            .values(rating=rating, updated_at=clock.now())
            .returning(Goal.rating)
            .execution_options(synchronize_session="fetch")
        )
        result = await self.db.execute(stmt)
        return result.scalar_one()

    async def list_missing_embeddings(self, limit: int) -> list[Goal]:
        """Goals whose description embedding is still null, oldest first (#96).

        A goal may have no description at all (the column is nullable), and
        such a row is returned like any other: deciding what an empty text
        means is the backfill's job, not the query's.
        """
        stmt = (
            select(Goal)
            .where(Goal.description_embedding.is_(None))
            .order_by(Goal.created_at, Goal.id)
            .limit(limit)
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def update(self, entity: Goal) -> Goal:
        await self.db.flush()
        return entity

    async def delete(self, entity_id: str) -> bool:
        stmt = sql_delete(Goal).where(Goal.id == entity_id)
        result = await self.db.execute(stmt)
        return result.rowcount > 0
