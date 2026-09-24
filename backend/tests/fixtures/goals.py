import pytest
from backend.models.goal import Goal


@pytest.fixture
def goal_factory(test_db):
    """Create a Goal for a student. Pass `active=True` to make it the student's
    active goal (students.current_goal_id)."""
    async def _create_goal(student, name="Learn Italian", description="Hold a chat.", active=False, **kwargs):
        goal = Goal(student_id=student.id, name=name, description=description, **kwargs)
        test_db.add(goal)
        await test_db.flush()
        if active:
            student.current_goal_id = goal.id
            await test_db.flush()
        return goal
    return _create_goal
