import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from backend.main import app
from backend.schemas.goal import GoalCreationFollowUpQuestionsResponse, GoalStudyPlanResponse
from unittest.mock import patch
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from backend.models.base import Base
from backend.core.database import get_db
from backend.models.student import Student
from backend.models.goal import Goal
from backend.models.objective import Objective

SQLALCHEMY_TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

test_engine = create_async_engine(
    SQLALCHEMY_TEST_DATABASE_URL,
    connect_args={"check_same_thread": False}  # Needed for SQLite
)

TestingSessionLocal = sessionmaker(
    test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

async def override_get_db():
    async with TestingSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
            
@pytest_asyncio.fixture
async def client():
    """Async test client fixture"""
    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()
    
@pytest_asyncio.fixture
async def test_db():
    """SQLite in-memory test database fixture"""
    # Create all tables
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    # Create a test database session
    async with TestingSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
            # Clean up after test
            async with test_engine.begin() as conn:
                await conn.run_sync(Base.metadata.drop_all)
    
@pytest.fixture
def mock_google_verify():
    """Fixture to mock Google token verification"""
    from google.oauth2 import id_token
    
    def mock_verify_oauth2_token(token, request, client_id):
        if token == "valid_google_token":
            return {
                "iss": "accounts.google.com",
                "sub": "12345",
                "email": "test1@example.com",
                "email_verified": True,
                "name": "Test User 1",
                "aud": client_id
            }
        elif token == "fixture_user_token":
            return {
                "iss": "accounts.google.com",
                "sub": "test_google_id_123",
                "email": "test@example.com",
                "email_verified": True,
                "name": "Test User",
                "aud": client_id
            }
        raise ValueError("Invalid token")

    with patch('google.oauth2.id_token.verify_oauth2_token', side_effect=mock_verify_oauth2_token) as mock:
        yield mock
    
@pytest.fixture
def mock_gemini_follow_up_questions():
    """Fixture to mock Gemini follow-up questions responses"""
    
    def mock_get_gemini_follow_up_questions(*args, **kwargs):
        return GoalCreationFollowUpQuestionsResponse(
            original_prompt="I want to learn Python. I just ran a 'hello world'. I wanna make apps",
            questions=["What is your current skill level in this area?", "How much time can you dedicate to this goal?", "What is your preferred learning style?", "Do you have any specific constraints or preferences?"]
        )

    # Patch where the function is imported and used, not where it's defined
    with patch('backend.utils.gemini.onboarding.get_gemini_follow_up_questions', side_effect=mock_get_gemini_follow_up_questions) as mock:
        yield mock
        
@pytest.fixture
def mock_gemini_study_plan():
    """Fixture to mock Gemini study plan responses"""
    
    def mock_get_gemini_study_plan(*args, **kwargs):
        return GoalStudyPlanResponse(
            goal_name="Build a Python Application",
            goal_description="Build a Python DataScience app and become Fluent in Python",
            first_objective_name="Write a simple python script",
            first_objective_description="Write a simple python script that reads and writes on the terminal",
            milestones=["Write a simple python script", "Write a full desktop app in Python", "Write a real Python app using pandas and numpy"]
        )
    with patch('backend.utils.gemini.onboarding.get_gemini_study_plan', side_effect=mock_get_gemini_study_plan) as mock:
        yield mock

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