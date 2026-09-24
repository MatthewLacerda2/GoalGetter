from dataclasses import dataclass
from datetime import datetime
from typing import Optional

from sqlalchemy import select, delete as sql_delete

from backend.models.lesson_answer import LessonAnswer
from backend.models.lesson_question import LessonQuestion
from backend.repositories.base import BaseRepository


@dataclass
class QuestionHistory:
    """A bank question and its **latest** answer, if it was ever answered.
    Lesson selection (services/lessons/selection.py) orders on this."""
    question: LessonQuestion
    last_answered_at: Optional[datetime]
    last_was_correct: Optional[bool]


class LessonQuestionRepository(BaseRepository[LessonQuestion]):

    async def create(self, entity: LessonQuestion) -> LessonQuestion:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity

    async def create_many(self, entities: list[LessonQuestion]) -> list[LessonQuestion]:
        if not entities:
            return []
        self.db.add_all(entities)
        await self.db.flush()
        return entities

    async def get_by_id(self, entity_id: str) -> Optional[LessonQuestion]:
        stmt = select(LessonQuestion).where(LessonQuestion.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_by_ids(self, question_ids: list) -> list[LessonQuestion]:
        if not question_ids:
            return []
        stmt = select(LessonQuestion).where(LessonQuestion.id.in_(question_ids))
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def list_bank_history(self, goal_id) -> list[QuestionHistory]:
        """Every question of the goal's bank with its latest answer (or none)."""
        bank_ids = select(LessonQuestion.id).where(LessonQuestion.goal_id == goal_id)
        latest = (
            select(LessonAnswer.question_id, LessonAnswer.created_at, LessonAnswer.is_correct)
            .where(LessonAnswer.question_id.in_(bank_ids))
            .distinct(LessonAnswer.question_id)
            .order_by(LessonAnswer.question_id, LessonAnswer.created_at.desc())
            .subquery()
        )
        stmt = (
            select(LessonQuestion, latest.c.created_at, latest.c.is_correct)
            .outerjoin(latest, latest.c.question_id == LessonQuestion.id)
            .where(LessonQuestion.goal_id == goal_id)
        )
        result = await self.db.execute(stmt)
        return [QuestionHistory(q, answered_at, correct) for q, answered_at, correct in result.all()]

    async def update(self, entity: LessonQuestion) -> LessonQuestion:
        await self.db.flush()
        return entity

    async def delete(self, entity_id: str) -> bool:
        stmt = sql_delete(LessonQuestion).where(LessonQuestion.id == entity_id)
        result = await self.db.execute(stmt)
        return result.rowcount > 0
