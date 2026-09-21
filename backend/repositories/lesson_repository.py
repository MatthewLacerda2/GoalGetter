from typing import Optional

from sqlalchemy import select, delete as sql_delete

from backend.models.lesson import Lesson
from backend.repositories.base import BaseRepository


class LessonRepository(BaseRepository[Lesson]):

    async def create(self, entity: Lesson) -> Lesson:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity

    async def get_by_id(self, entity_id: str) -> Optional[Lesson]:
        stmt = select(Lesson).where(Lesson.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_in_goal_for_update(self, lesson_id, goal_id) -> Optional[Lesson]:
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

    async def update(self, entity: Lesson) -> Lesson:
        await self.db.flush()
        return entity

    async def delete(self, entity_id: str) -> bool:
        stmt = sql_delete(Lesson).where(Lesson.id == entity_id)
        result = await self.db.execute(stmt)
        return result.rowcount > 0
