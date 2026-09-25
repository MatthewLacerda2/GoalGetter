import pytest

from backend.models.goal import Goal
from backend.repositories.goal_repository import GoalRepository


@pytest.fixture
def goal_factory(test_db):
    """Create a Goal for a student. Pass `active=True` to make it the student's
    active goal (students.current_goal_id).

    It goes through the repository rather than adding the row, because that is
    what writes the goal's first frontier (#133): a goal with no frontier is a
    state production cannot reach, and a fixture that could build one would let
    the suite pass on a database the app never sees.
    """

    async def _create_goal(
        student, name="Learn Italian", description="Hold a chat.", active=False, **kwargs
    ):
        goal = await GoalRepository(test_db).create(
            Goal(student_id=student.id, name=name, description=description, **kwargs)
        )
        if active:
            student.current_goal_id = goal.id
            await test_db.flush()
        return goal

    return _create_goal
