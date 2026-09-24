from datetime import datetime

from sqlalchemy import delete as sql_delete
from sqlalchemy import select

from backend.models.goal import Goal
from backend.models.lesson import Lesson
from backend.repositories.base import BaseRepository


class LessonRepository(BaseRepository[Lesson]):
    async def create(self, entity: Lesson) -> Lesson:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity

    async def get_by_id(self, entity_id: str) -> Lesson | None:
        stmt = select(Lesson).where(Lesson.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_in_goal_for_update(self, lesson_id, goal_id) -> Lesson | None:
        """The lesson, if it belongs to this goal, row-locked until the commit.

        The lock is what makes a double submit a clean 409: the second request
        waits for the first to commit, then sees `finished_at` set.
        """
        stmt = (
            select(Lesson)
            .where(Lesson.id == lesson_id, Lesson.goal_id == goal_id)
            .with_for_update()
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_finished_by_goal(self, goal_id) -> list[Lesson]:
        """The goal's answered lessons, oldest first (Home's elo history)."""
        stmt = (
            select(Lesson)
            .where(Lesson.goal_id == goal_id, Lesson.finished_at.is_not(None))
            .order_by(Lesson.finished_at.asc())
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def list_recent_finished_by_goal(self, goal_id, limit: int) -> list[Lesson]:
        """The goal's last `limit` answered lessons, newest first."""
        stmt = (
            select(Lesson)
            .where(Lesson.goal_id == goal_id, Lesson.finished_at.is_not(None))
            .order_by(Lesson.finished_at.desc())
            .limit(limit)
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def list_finished_at_by_student(self, student_id) -> list[datetime]:
        """When each of the student's lessons was answered, on any goal, newest first.

        Timestamps, not dates: the streak buckets them by the server's local
        date in Python (services/lessons/streak.py), so the rule does not
        depend on the database session's time zone.
        """
        stmt = (
            select(Lesson.finished_at)
            .join(Goal, Goal.id == Lesson.goal_id)
            .where(Goal.student_id == student_id, Lesson.finished_at.is_not(None))
            .order_by(Lesson.finished_at.desc())
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def update(self, entity: Lesson) -> Lesson:
        await self.db.flush()
        return entity

    async def delete(self, entity_id: str) -> bool:
        stmt = sql_delete(Lesson).where(Lesson.id == entity_id)
        result = await self.db.execute(stmt)
        return result.rowcount > 0
