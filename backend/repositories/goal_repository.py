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

    async def update(self, entity: Goal) -> Goal:
        await self.db.flush()
        return entity

    async def delete(self, entity_id: str) -> bool:
        stmt = sql_delete(Goal).where(Goal.id == entity_id)
        result = await self.db.execute(stmt)
        return result.rowcount > 0
