from sqlalchemy import delete as sql_delete
from sqlalchemy import select
from sqlalchemy import update as sql_update

from backend.core import clock
from backend.models.frontier import Frontier
from backend.models.goal import Goal
from backend.repositories.base import BaseRepository


class GoalRepository(BaseRepository[Goal]):
    async def create(self, entity: Goal) -> Goal:
        """Store a goal and, with it, the first frontier of that goal (#133).

        It is written here because this is the only place a goal is born, and
        "a goal always has exactly one current frontier" is only true if
        nothing can create one without it. Nothing downstream then handles "no
        frontier yet".

        The first definition is the description the student approved: on day
        one, what he asked for and what we are teaching him are the same
        sentence - they stop being the same on about the second week, which is
        the whole reason the two are separate rows. It carries the goal's own
        `created_at` so a goal seeded with a past date does not get a frontier
        dated today, and the empty string stands for a goal with no
        description: as empty as what it was written from.
        """
        self.db.add(entity)
        await self.db.flush()
        self.db.add(
            Frontier(
                goal_id=entity.id,
                definition=entity.description or "",
                created_at=entity.created_at,
            )
        )
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

    async def add_to_rating(self, goal_id, delta: int) -> int:
        """Move the goal's rating by `delta` in one statement; return the new rating.

        Atomic on purpose (#72): a read-then-write in Python lets two lessons
        finishing at once both read the same rating and lose one delta.
        `updated_at` is set here because a Core-style UPDATE does not fire the
        column's ORM `onupdate`. The session's copy of the goal is synchronized
        ("fetch"), so a later flush cannot write a stale rating back over it.
        """
        stmt = (
            sql_update(Goal)
            .where(Goal.id == goal_id)
            .values(rating=Goal.rating + delta, updated_at=clock.now())
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
