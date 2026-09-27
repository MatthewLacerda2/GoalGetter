import uuid
from dataclasses import dataclass
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import distinct_on

from backend.models.question import Question
from backend.models.student_answer import StudentAnswer
from backend.repositories.base import BaseRepository


@dataclass
class QuestionHistory:
    """A bank question and its **latest** answer, if it was ever answered.

    `last_selected_index` is the option he actually picked. It is here because
    *which* wrong answer he gave is what the generation prompt carries:
    a wrong answer says little, and the option he chose says what he believes.
    """

    question: Question
    last_answered_at: datetime | None
    last_was_correct: bool | None
    last_selected_index: int | None = None


class QuestionRepository(BaseRepository[Question]):
    model = Question

    async def create_many(self, entities: list[Question]) -> list[Question]:
        if not entities:
            return []
        self.db.add_all(entities)
        await self.db.flush()
        return entities

    async def list_by_goal(self, goal_id: uuid.UUID) -> list[Question]:
        """The goal's whole bank. What a submission is checked against: an
        answer naming anything else is not this student's question.

        Oldest first, the id breaking a tie: the order the rating walk
        and the selection already sort the bank into, so every reader sees one
        order rather than whichever the table happens to hold."""
        stmt = (
            select(Question)
            .where(Question.goal_id == goal_id)
            .order_by(Question.created_at, Question.id)
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def list_bank_history(self, goal_id: uuid.UUID) -> list[QuestionHistory]:
        """Every question of the goal's bank with its latest answer (or none).

        Correctness is derived here, from the answer's index against the
        question's own: `student_answers` stores no `is_correct`, so
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
        """Bank questions whose embedding is still null, oldest first.

        Lesson selection reads the column (`services/lessons/selection.py`:
        how close a question sits to the frontier, to his context and to the
        rest of the lesson), and must never require it: a null scores as
        neutral, so selection still works on a bank of nulls.
        """
        stmt = (
            select(Question)
            .where(Question.text_embedding.is_(None))
            .order_by(Question.created_at, Question.id)
            .limit(limit)
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())
