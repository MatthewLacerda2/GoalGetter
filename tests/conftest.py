import pytest

# Import all fixtures so pytest can discover them
pytest_plugins = [
    "tests.fixtures.database",
    "tests.fixtures.auth", 
    "tests.fixtures.gemini",
    "tests.fixtures.users",
    "tests.fixtures.clients",
]

@pytest.fixture(autouse=True)
def mock_account_creation_tasks(monkeypatch):
    """Mock account_creation_tasks to prevent it from running in background during tests"""
    async def mock_account_creation_tasks(*args, **kwargs):
        pass
    
    from backend.services import account_creation_tasks as act_module
    monkeypatch.setattr(act_module, 'account_creation_tasks', mock_account_creation_tasks)

@pytest.fixture(autouse=True)
def mock_create_lesson_questions_async(monkeypatch):
    """Mock create_lesson_questions_async - allows direct calls to create fake questions, blocks background tasks"""
    from backend.api.v1.endpoints.activities import create_lesson_questions_async as original_func
    from backend.api.v1.endpoints import activities
    
    async def mock_create_lesson_questions_async(student_id: str, goal_id: str, num_questions: int, db, **kwargs):
        # If db is provided (direct call), run the real function with mocked gemini
        # The gemini mock will provide fake questions that get stored in the database
        if db is not None:
            return await original_func(student_id, goal_id, num_questions, db)
        # Otherwise it's a background task, skip it
        pass
    
    monkeypatch.setattr(activities, 'create_lesson_questions_async', mock_create_lesson_questions_async)

@pytest.fixture(autouse=True)
def mock_save_evaluation_data(monkeypatch):
    """Mock save_evaluation_data background task to prevent it from running in tests"""
    async def mock_save_evaluation_data(*args, **kwargs):
        pass
    
    from backend.api.v1.endpoints import assessments
    monkeypatch.setattr(assessments, 'save_evaluation_data', mock_save_evaluation_data)