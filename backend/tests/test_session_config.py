import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from backend.core.database import AsyncSessionLocal
from backend.models.student import Student
from backend.tests.fixtures.database import test_engine


@pytest.mark.asyncio
async def test_production_session_can_read_what_it_just_committed(setup_test_db):
    """Endpoints build their response from rows they just committed. With the
    production session's settings, that read must not lazy-load (MissingGreenlet)."""
    settings = {k: v for k, v in AsyncSessionLocal.kw.items() if k != "bind"}
    async with AsyncSession(test_engine, **settings) as session:
        student = Student(email="commit@example.com", google_id="commit-read", name="Commit")
        session.add(student)
        await session.commit()
        try:
            assert student.id is not None and student.name == "Commit"
        finally:
            await session.delete(student)
            await session.commit()
