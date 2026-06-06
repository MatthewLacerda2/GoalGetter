import pytest
import pytest_asyncio
from backend.models.student import Student

@pytest.fixture
def student_factory(test_db):
    """Factory to create Student models dynamically"""
    async def _create_student(email="test@example.com", google_id="test_google_id_123", name="Test User", **kwargs):
        student = Student(email=email, google_id=google_id, name=name, **kwargs)
        test_db.add(student)
        await test_db.flush()
        return student
    return _create_student

@pytest_asyncio.fixture
async def test_user(test_db, student_factory):
    """Fixture to create a test user for testing"""
    student = await student_factory()
    await test_db.commit()
    await test_db.refresh(student)
    return student