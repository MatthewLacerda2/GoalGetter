from sqlalchemy import delete as sql_delete
from sqlalchemy import select

from backend.models.goal import Goal
from backend.models.lesson_answer import LessonAnswer
from backend.models.lesson_question import LessonQuestion
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

    async def get_by_id(self, entity_id: str) -> LessonAnswer | None:
        stmt = select(LessonAnswer).where(LessonAnswer.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_by_lesson(self, lesson_id) -> list[LessonAnswer]:
        stmt = select(LessonAnswer).where(LessonAnswer.lesson_id == lesson_id)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def list_recent_by_student(
        self, student_id, limit: int
    ) -> list[tuple[LessonAnswer, LessonQuestion]]:
        """The student's most recent answers on any goal, newest first, each
        paired with the question it answered.

        Across goals on purpose: the chain's context step is writing about the
        person, and someone who is careless in law is careless in history.
        """
        stmt = (
            select(LessonAnswer, LessonQuestion)
            .join(LessonQuestion, LessonQuestion.id == LessonAnswer.question_id)
            .join(Goal, Goal.id == LessonQuestion.goal_id)
            .where(Goal.student_id == student_id)
            .order_by(LessonAnswer.created_at.desc())
            .limit(limit)
        )
        result = await self.db.execute(stmt)
        return [(answer, question) for answer, question in result.all()]

    async def update(self, entity: LessonAnswer) -> LessonAnswer:
        await self.db.flush()
        return entity

    async def delete(self, entity_id: str) -> bool:
        stmt = sql_delete(LessonAnswer).where(LessonAnswer.id == entity_id)
        result = await self.db.execute(stmt)
        return result.rowcount > 0
