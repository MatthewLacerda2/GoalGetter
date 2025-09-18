import pytest
import pytest_asyncio
from backend.models.student import Student
from backend.models.goal import Goal
from backend.models.objective import Objective

@pytest_asyncio.fixture
async def test_user(test_db):
    """Fixture to create a test user with goal for testing"""
    
    student = Student(
        email="test@example.com",
        google_id="test_google_id_123",
        name="Test User",
    )
    test_db.add(student)
    await test_db.flush()
    
    await test_db.commit()
    await test_db.refresh(student)
    
    yield student

@pytest_asyncio.fixture
async def test_user_with_objective(test_user, test_db):
    """Fixture to create a test user with goal and objective for testing"""
    
    goal = Goal(
        name="Learn Python Programming",
        description="Master Python programming fundamentals and build applications"
    )
    test_db.add(goal)
    await test_db.flush()
    
    test_user.goal_id = goal.id
    test_user.goal_name = goal.name
    test_db.add(test_user)
    await test_db.flush()
    
    objective = Objective(
        goal_id=goal.id,
        name="Complete Python Basics",
        description="Learn variables, data types, control structures, and functions in Python",
    )
    test_db.add(objective)
    await test_db.flush()
    
    await test_db.commit()
    await test_db.refresh(test_user)
    await test_db.refresh(goal)
    await test_db.refresh(objective)
    
    yield test_user