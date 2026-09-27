import uuid

from sqlalchemy import select
from sqlalchemy import update as sql_update

from backend.core import clock
from backend.models.frontier import Frontier
from backend.models.goal import Goal
from backend.models.student import Student
from backend.repositories.base import DeletableRepository


class GoalRepository(DeletableRepository[Goal]):
    model = Goal

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

    async def list_by_student(self, student_id: uuid.UUID) -> list[Goal]:
        """The student's goals, newest first."""
        stmt = select(Goal).where(Goal.student_id == student_id).order_by(Goal.created_at.desc())
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def list_active(self, student_id: uuid.UUID) -> list[Goal]:
        """The goal the student is working on - the one he picked on his
        profile - as a list of one, or none when he has not picked any.

        What the background jobs write for (the user, 2026-09-26): a goal he is
        not working on is not one he unlearned, it is one he paused, and nothing
        needs refreshing for it until he picks it again. A list, so a step reads
        the same whether it gets one goal or none.
        """
        stmt = (
            select(Goal)
            .join(Student, Student.current_goal_id == Goal.id)
            .where(Student.id == student_id)
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def set_rating(self, goal_id: uuid.UUID, rating: int) -> int:
        """Write the goal's rating, and return it.

        The rating is *replayed* from the whole answer history, never
        incremented, so what is written is a fact about the history and not the
        result of a read-then-write: two lessons finishing at once cannot
        lose a delta between them, and a rating that somehow drifted is repaired
        by the next submission rather than carried forever.

        `updated_at` is set here because a Core-style UPDATE does not fire the
        column's ORM `onupdate`, and the goals list reads it as "last
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
        """Goals whose description embedding is still null, oldest first.

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
