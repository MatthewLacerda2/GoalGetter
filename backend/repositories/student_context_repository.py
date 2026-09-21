from typing import Optional

from sqlalchemy import select, delete as sql_delete

from backend.models.student_context import StudentContext
from backend.repositories.base import BaseRepository


class StudentContextRepository(BaseRepository[StudentContext]):
    """The app's memory of a learner, per student+goal. A stale context is
    retired with `is_still_valid = False`, never deleted: it is progression
    history (see backend_contract.md, Student context)."""

    async def create(self, entity: StudentContext) -> StudentContext:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity

    async def get_by_id(self, entity_id: str) -> Optional[StudentContext]:
        stmt = select(StudentContext).where(StudentContext.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_valid(self, student_id, goal_id) -> list[StudentContext]:
        """Still-valid contexts for this student and goal, newest first."""
        stmt = (
            select(StudentContext)
            .where(
                StudentContext.student_id == student_id,
                StudentContext.goal_id == goal_id,
                StudentContext.is_still_valid.is_(True),
            )
            .order_by(StudentContext.created_at.desc())
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def update(self, entity: StudentContext) -> StudentContext:
        await self.db.flush()
        return entity

    async def delete(self, entity_id: str) -> bool:
        stmt = sql_delete(StudentContext).where(StudentContext.id == entity_id)
        result = await self.db.execute(stmt)
        return result.rowcount > 0
