from sqlalchemy import or_, select

from backend.models.student_context import StudentContext
from backend.repositories.base import BaseRepository


class StudentContextRepository(BaseRepository[StudentContext]):
    """The app's memory of a learner, per student (#87). A stale context is
    retired with `is_still_valid = False`, never deleted: it is progression
    history (see backend_contract.md, Student context)."""

    model = StudentContext

    async def list_valid(self, student_id) -> list[StudentContext]:
        """The student's still-valid contexts, newest first. Every goal of
        theirs reads the same ones."""
        stmt = (
            select(StudentContext)
            .where(
                StudentContext.student_id == student_id,
                StudentContext.is_still_valid.is_(True),
            )
            .order_by(StudentContext.created_at.desc())
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def list_missing_embeddings(self, limit: int) -> list[StudentContext]:
        """Contexts with either embedding still null, oldest first (#96).

        Retired readings (`is_still_valid = False`) are included on purpose:
        they are progression history the student can read, and history is
        exactly what a later similarity question would be asked about.
        """
        stmt = (
            select(StudentContext)
            .where(
                or_(
                    StudentContext.state_embedding.is_(None),
                    StudentContext.metacognition_embedding.is_(None),
                )
            )
            .order_by(StudentContext.created_at, StudentContext.id)
            .limit(limit)
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())
