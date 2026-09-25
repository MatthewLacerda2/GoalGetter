from dataclasses import dataclass
from datetime import datetime

from sqlalchemy import case, func, select
from sqlalchemy import delete as sql_delete

from backend.models.goal import Goal
from backend.models.question import Question
from backend.models.student_answer import StudentAnswer
from backend.repositories.base import BaseRepository


@dataclass
class LessonSummary:
    """One lesson as Home reads it: the answers that carry the same mark,
    counted together (#131). There is no row behind it - the grouping *is* the
    lesson, which is why accuracy and seconds are computed and not stored."""

    lesson_id: str
    answered_at: datetime
    total_seconds: int
    accuracy: float  # 0..100


# Whether one answer was right, as SQL. The only definition there is: the
# column was deliberately not stored (#131).
_IS_RIGHT = StudentAnswer.selected_index == Question.right_answer_index


class StudentAnswerRepository(BaseRepository[StudentAnswer]):
    async def create(self, entity: StudentAnswer) -> StudentAnswer:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity

    async def create_many(self, entities: list[StudentAnswer]) -> list[StudentAnswer]:
        if not entities:
            return []
        self.db.add_all(entities)
        await self.db.flush()
        return entities

    async def get_by_id(self, entity_id: str) -> StudentAnswer | None:
        stmt = select(StudentAnswer).where(StudentAnswer.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_by_lesson(self, lesson_id) -> list[StudentAnswer]:
        """The answers that arrived in one submission, in the order they were
        asked - which is what `position` is for."""
        stmt = (
            select(StudentAnswer)
            .where(StudentAnswer.lesson_id == lesson_id)
            .order_by(StudentAnswer.position)
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def list_for_question(self, question_id) -> list[StudentAnswer]:
        """Every answer this question ever received, oldest first.

        The history the whole change exists for: the same question answered on
        three days is three rows, read back in the order they were given.
        """
        stmt = (
            select(StudentAnswer)
            .where(StudentAnswer.question_id == question_id)
            .order_by(StudentAnswer.created_at)
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def list_recent_lessons_by_goal(self, goal_id, limit: int) -> list[LessonSummary]:
        """The goal's last `limit` lessons, newest first, as Home shows them.

        A lesson is a `lesson_id` shared by a batch of answers, so this is a
        GROUP BY and not a table read. The moment is the last answer of the
        batch: they are written in one transaction, so it is when the student
        finished.
        """
        answered_at = func.max(StudentAnswer.created_at).label("answered_at")
        stmt = (
            select(
                StudentAnswer.lesson_id,
                answered_at,
                func.coalesce(func.sum(StudentAnswer.total_seconds), 0),
                func.count(),
                func.count(case((_IS_RIGHT, 1))),
            )
            .join(Question, Question.id == StudentAnswer.question_id)
            .where(Question.goal_id == goal_id)
            .group_by(StudentAnswer.lesson_id)
            .order_by(answered_at.desc())
            .limit(limit)
        )
        result = await self.db.execute(stmt)
        return [
            LessonSummary(
                lesson_id=str(lesson_id),
                answered_at=moment,
                total_seconds=int(seconds),
                accuracy=round(100 * right / total, 1),
            )
            for lesson_id, moment, seconds, total, right in result.all()
        ]

    async def list_recent_by_student(
        self, student_id, limit: int
    ) -> list[tuple[StudentAnswer, Question]]:
        """The student's most recent answers on any goal, newest first, each
        paired with the question it answered.

        Across goals on purpose: the chain's context step is writing about the
        person, and someone who is careless in law is careless in history.
        """
        stmt = (
            select(StudentAnswer, Question)
            .join(Question, Question.id == StudentAnswer.question_id)
            .join(Goal, Goal.id == Question.goal_id)
            .where(Goal.student_id == student_id)
            .order_by(StudentAnswer.created_at.desc())
            .limit(limit)
        )
        result = await self.db.execute(stmt)
        return [(answer, question) for answer, question in result.all()]

    async def last_answered_at(self, student_id) -> datetime | None:
        """When this student last answered a question, on any goal, or None.

        The nightly run's whole gate (#89) is this one moment: a day counts
        because the student answered something in it. Chat activity is
        deliberately not part of it.
        """
        stmt = self._answered_at(student_id).limit(1)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_answered_at_by_student(self, student_id) -> list[datetime]:
        """When each of the student's answers was given, on any goal, newest first.

        Timestamps, not dates: the streak buckets them by the app's calendar
        day in Python (services/lessons/streak.py), so the rule does not depend
        on the database session's time zone (#92).
        """
        result = await self.db.execute(self._answered_at(student_id))
        return list(result.scalars().all())

    @staticmethod
    def _answered_at(student_id):
        return (
            select(StudentAnswer.created_at)
            .join(Question, Question.id == StudentAnswer.question_id)
            .join(Goal, Goal.id == Question.goal_id)
            .where(Goal.student_id == student_id)
            .order_by(StudentAnswer.created_at.desc())
        )

    async def update(self, entity: StudentAnswer) -> StudentAnswer:
        await self.db.flush()
        return entity

    async def delete(self, entity_id: str) -> bool:
        stmt = sql_delete(StudentAnswer).where(StudentAnswer.id == entity_id)
        result = await self.db.execute(stmt)
        return result.rowcount > 0
