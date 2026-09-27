from sqlalchemy import select

from backend.models.student import Student
from backend.repositories.base import DeletableRepository


class StudentRepository(DeletableRepository[Student]):
    model = Student

    async def list_ids(self) -> list:
        """Every student's id, oldest first.

        What the nightly run (#89) iterates. Ids only: the run decides per
        student from that student's own rows, and holding every Student object
        in memory to read nothing off them would be waste that grows with the
        user base.
        """
        stmt = select(Student.id).order_by(Student.created_at.asc())
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_by_google_id(self, google_id: str) -> Student | None:
        stmt = select(Student).where(Student.google_id == google_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
