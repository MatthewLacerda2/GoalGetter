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
    """Mock create_lesson_questions_async to prevent it from running in background during tests"""
    async def mock_create_lesson_questions_async(*args, **kwargs):
        pass
    
    from backend.api.v1.endpoints import activities
    monkeypatch.setattr(activities, 'create_lesson_questions_async', mock_create_lesson_questions_async)

@pytest.fixture(autouse=True)
def mock_save_evaluation_data(monkeypatch):
    """Mock save_evaluation_data background task to prevent it from running in tests"""
    async def mock_save_evaluation_data(*args, **kwargs):
        pass
    
    from backend.api.v1.endpoints import assessments
    monkeypatch.setattr(assessments, 'save_evaluation_data', mock_save_evaluation_data)