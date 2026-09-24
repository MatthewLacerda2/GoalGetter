import pytest

from backend.models.student_context import StudentContext
from backend.repositories.student_context_repository import StudentContextRepository


@pytest.mark.asyncio
async def test_list_valid_skips_retired_and_other_goals(test_db, test_user, goal_factory):
    goal, other_goal = await goal_factory(test_user), await goal_factory(test_user, name="Chess")
    repo = StudentContextRepository(test_db)
    kept = await repo.create(
        StudentContext(student_id=test_user.id, goal_id=goal.id, state="s", metacognition="m")
    )
    await repo.create(
        StudentContext(
            student_id=test_user.id,
            goal_id=goal.id,
            state="old",
            metacognition="m",
            is_still_valid=False,
        )
    )
    await repo.create(
        StudentContext(student_id=test_user.id, goal_id=other_goal.id, state="x", metacognition="m")
    )

    assert [c.id for c in await repo.list_valid(test_user.id, goal.id)] == [kept.id]
