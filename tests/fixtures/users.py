import pytest
import pytest_asyncio
from backend.models.student import Student
from backend.models.goal import Goal
from backend.models.objective import Objective

@pytest_asyncio.fixture
async def test_user(test_db):
    """Fixture to create a test user with goal and objective for testing"""
    
    # Create goal first
    goal = Goal(
        name="Learn Python Programming",
        description="Master Python programming fundamentals and build applications"
    )
    test_db.add(goal)
    await test_db.flush()
    
    # Create objective
    objective = Objective(
        goal_id=goal.id,
        name="Complete Python Basics",
        description="Learn variables, data types, control structures, and functions in Python",
    )
    test_db.add(objective)
    await test_db.flush()
    
    # Create student with goal and objective
    student = Student(
        email="test@example.com",
        google_id="test_google_id_123",
        name="Test User",
        goal_id=goal.id,
        goal_name=goal.name,
        current_objective_id=objective.id,
        current_objective_name=objective.name,
    )
    test_db.add(student)
    await test_db.flush()
    
    await test_db.commit()
    await test_db.refresh(student)
    await test_db.refresh(goal)
    await test_db.refresh(objective)
    
    yield student