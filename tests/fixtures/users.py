from backend.models.student import Student
from backend.models.goal import Goal
from backend.models.objective import Objective
from backend.models.multiple_choice_question import MultipleChoiceQuestion
from backend.utils.envs import NUM_QUESTIONS_PER_LESSON
import pytest_asyncio

@pytest_asyncio.fixture
async def test_user(test_db):
    """Fixture to create a test user with goal and objective for testing"""
    
    goal = Goal(
        name="Learn Python Programming",
        description="Master Python programming fundamentals and build applications"
    )
    test_db.add(goal)
    await test_db.flush()
    
    objective = Objective(
        goal_id=goal.id,
        name="Complete Python Basics",
        description="Learn variables, data types, control structures, and functions in Python",
        ai_model="test-model",
    )
    test_db.add(objective)
    await test_db.flush()
    
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

@pytest_asyncio.fixture
async def test_multiple_choice_questions(test_db, test_user):
    """Fixture to create multiple choice questions for testing"""
    
    questions = [MultipleChoiceQuestion(
        id=f"id_{i}",
        objective_id=test_user.current_objective_id,
        question=f"Question {i}",
        choices=["A","B","C","D"],
        correct_answer_index=0,
        xp=1
    ) for i in range (NUM_QUESTIONS_PER_LESSON)]
    test_db.add_all(questions)
    
    await test_db.flush()
    await test_db.commit()
    
    for question in questions:
        await test_db.refresh(question)
    
    yield questions