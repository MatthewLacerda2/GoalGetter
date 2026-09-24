from typing import Optional

from sqlalchemy import select, delete as sql_delete

from backend.models.lesson_answer import LessonAnswer
from backend.repositories.base import BaseRepository


class LessonAnswerRepository(BaseRepository[LessonAnswer]):

    async def create(self, entity: LessonAnswer) -> LessonAnswer:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity

    async def create_many(self, entities: list[LessonAnswer]) -> list[LessonAnswer]:
        if not entities:
            return []
        self.db.add_all(entities)
        await self.db.flush()
        return entities

    async def get_by_id(self, entity_id: str) -> Optional[LessonAnswer]:
        stmt = select(LessonAnswer).where(LessonAnswer.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_by_lesson(self, lesson_id) -> list[LessonAnswer]:
        stmt = select(LessonAnswer).where(LessonAnswer.lesson_id == lesson_id)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def update(self, entity: LessonAnswer) -> LessonAnswer:
        await self.db.flush()
        return entity

    async def delete(self, entity_id: str) -> bool:
        stmt = sql_delete(LessonAnswer).where(LessonAnswer.id == entity_id)
        result = await self.db.execute(stmt)
        return result.rowcount > 0
