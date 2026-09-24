import pytest

from backend.models.student_context import StudentContext
from backend.repositories.student_context_repository import StudentContextRepository


@pytest.mark.asyncio
async def test_list_valid_skips_retired_and_other_students(test_db, test_user, student_factory):
    """A context belongs to the student (#87): every goal of theirs reads the
    same ones, and a retired one is kept but not read."""
    stranger = await student_factory(email="other@example.com", google_id="other")
    repo = StudentContextRepository(test_db)
    kept = await repo.create(StudentContext(student_id=test_user.id, state="s", metacognition="m"))
    await repo.create(
        StudentContext(
            student_id=test_user.id, state="old", metacognition="m", is_still_valid=False
        )
    )
    await repo.create(StudentContext(student_id=stranger.id, state="x", metacognition="m"))

    assert [c.id for c in await repo.list_valid(test_user.id)] == [kept.id]
