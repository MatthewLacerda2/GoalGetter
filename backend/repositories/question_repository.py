from dataclasses import dataclass
from datetime import datetime

from sqlalchemy import delete as sql_delete
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import distinct_on

from backend.models.question import Question
from backend.models.student_answer import StudentAnswer
from backend.repositories.base import BaseRepository


@dataclass
class QuestionHistory:
    """A bank question and its **latest** answer, if it was ever answered.

    `last_selected_index` is the option he actually picked. It is here because
    *which* wrong answer he gave is what the generation prompt carries (#135):
    a wrong answer says little, and the option he chose says what he believes.
    """

    question: Question
    last_answered_at: datetime | None
    last_was_correct: bool | None
    last_selected_index: int | None = None


class QuestionRepository(BaseRepository[Question]):
    async def create(self, entity: Question) -> Question:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity

    async def create_many(self, entities: list[Question]) -> list[Question]:
        if not entities:
            return []
        self.db.add_all(entities)
        await self.db.flush()
        return entities

    async def get_by_id(self, entity_id: str) -> Question | None:
        stmt = select(Question).where(Question.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_by_goal(self, goal_id) -> list[Question]:
        """The goal's whole bank. What a submission is checked against: an
        answer naming anything else is not this student's question (#131)."""
        stmt = select(Question).where(Question.goal_id == goal_id)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def list_bank_history(self, goal_id) -> list[QuestionHistory]:
        """Every question of the goal's bank with its latest answer (or none).

        Correctness is derived here, from the answer's index against the
        question's own: `student_answers` stores no `is_correct` (#131), so
        this join is where "was it right" is decided, once, for every reader.
        """
        bank_ids = select(Question.id).where(Question.goal_id == goal_id)
        latest = (
            select(
                StudentAnswer.question_id,
                StudentAnswer.created_at,
                StudentAnswer.selected_index,
            )
            .where(StudentAnswer.question_id.in_(bank_ids))
            .ext(distinct_on(StudentAnswer.question_id))
            .order_by(StudentAnswer.question_id, StudentAnswer.created_at.desc())
            .subquery()
        )
        stmt = (
            select(Question, latest.c.created_at, latest.c.selected_index)
            .outerjoin(latest, latest.c.question_id == Question.id)
            .where(Question.goal_id == goal_id)
        )
        result = await self.db.execute(stmt)
        return [
            QuestionHistory(
                question,
                answered_at,
                None if answered_at is None else selected == question.right_answer_index,
                selected,
            )
            for question, answered_at, selected in result.all()
        ]

    async def list_missing_embeddings(self, limit: int) -> list[Question]:
        """Bank questions whose embedding is still null, oldest first (#96).

        The column with a use already named: reading a question's topic and
        difficulty inside one student's own bank. Nothing reads it yet, and
        nothing may start requiring it - selection still works on a bank of
        nulls.
        """
        stmt = (
            select(Question)
            .where(Question.text_embedding.is_(None))
            .order_by(Question.created_at, Question.id)
            .limit(limit)
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def update(self, entity: Question) -> Question:
        await self.db.flush()
        return entity

    async def delete(self, entity_id: str) -> bool:
        stmt = sql_delete(Question).where(Question.id == entity_id)
        result = await self.db.execute(stmt)
        return result.rowcount > 0
