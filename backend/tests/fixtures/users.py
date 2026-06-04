import pytest
import pytest_asyncio
from backend.models.student import Student
from backend.models.goal import Goal
from backend.models.objective import Objective
from backend.models.multiple_choice_question import MultipleChoiceQuestion
from backend.utils.envs import NUM_QUESTIONS_PER_LESSON

@pytest.fixture
def student_factory(test_db):
    """Factory to create Student models dynamically"""
    async def _create_student(email="test@example.com", google_id="test_google_id_123", name="Test User", **kwargs):
        student = Student(email=email, google_id=google_id, name=name, **kwargs)
        test_db.add(student)
        await test_db.flush()
        return student
    return _create_student

@pytest.fixture
def goal_factory(test_db):
    """Factory to create Goal models dynamically"""
    async def _create_goal(student_id, name="Learn Python Programming", description="Master Python programming fundamentals and build applications", **kwargs):
        goal = Goal(student_id=student_id, name=name, description=description, **kwargs)
        test_db.add(goal)
        await test_db.flush()
        return goal
    return _create_goal

@pytest.fixture
def objective_factory(test_db):
    """Factory to create Objective models dynamically"""
    async def _create_objective(goal_id, name="Complete Python Basics", description="Learn variables, data types, control structures, and functions in Python", ai_model="test-model", **kwargs):
        objective = Objective(goal_id=goal_id, name=name, description=description, ai_model=ai_model, **kwargs)
        test_db.add(objective)
        await test_db.flush()
        return objective
    return _create_objective

@pytest.fixture
def question_factory(test_db):
    """Factory to create MultipleChoiceQuestion models dynamically"""
    async def _create_questions(objective_id, count=NUM_QUESTIONS_PER_LESSON, ai_model="test-model"):
        questions = [
            MultipleChoiceQuestion(
                objective_id=objective_id,
                question=f"Question {i}",
                option_a="A",
                option_b="B",
                option_c="C",
                option_d="D",
                correct_answer_index=0,
                ai_model=ai_model
            ) for i in range(count)
        ]
        test_db.add_all(questions)
        await test_db.flush()
        return questions
    return _create_questions

@pytest_asyncio.fixture
async def test_user(test_db, student_factory, goal_factory, objective_factory):
    """Fixture to create a test user with goal and objective for testing"""
    student = await student_factory()
    goal = await goal_factory(student_id=student.id)
    objective = await objective_factory(goal_id=goal.id)
    
    # Update student to set active goal and objective
    student.goal_id = goal.id
    student.goal_name = goal.name
    student.current_objective_id = objective.id
    student.current_objective_name = objective.name
    
    await test_db.flush()
    await test_db.commit()
    
    await test_db.refresh(student)
    await test_db.refresh(goal)
    await test_db.refresh(objective)
    
    return student

@pytest_asyncio.fixture
async def test_multiple_choice_questions(test_db, test_user, question_factory):
    """Fixture to create multiple choice questions for testing"""
    questions = await question_factory(objective_id=test_user.current_objective_id)
    
    await test_db.commit()
    for question in questions:
        await test_db.refresh(question)
    
    return questions

@pytest_asyncio.fixture
async def chat_messages(test_db, test_user):
    """Fixture to create a set of chat messages for testing"""
    import uuid
    from datetime import datetime
    from backend.models.chat_message import ChatMessage
    
    TEST_NAMESPACE = uuid.UUID('00000000-0000-0000-0000-000000000001')
    messages = []
    for i in range(15):
        msg = ChatMessage(
            id=uuid.uuid5(TEST_NAMESPACE, f"Message {i}"),
            message=f"Message {i}",
            sender_id=str(test_user.id),
            array_id="array1",
            created_at=datetime.now(),
            student_id=test_user.id
        )
        test_db.add(msg)
        messages.append(msg)
    await test_db.commit()
    return messages

@pytest.fixture
def student_context_factory(test_db):
    """Factory to create StudentContext models dynamically"""
    import uuid
    from datetime import datetime
    from backend.models.student_context import StudentContext
    
    async def _create_contexts(student_id, goal_id, objective_id, count=3):
        TEST_NAMESPACE = uuid.UUID('00000000-0000-0000-0000-000000000001')
        contexts = []
        for i in range(count):
            context = StudentContext(
                id=uuid.uuid5(TEST_NAMESPACE, f"Context {i}"),
                student_id=student_id,
                goal_id=goal_id,
                objective_id=objective_id,
                source="student",
                state=f"Test context state {i}",
                metacognition="",
                state_embedding=None,
                metacognition_embedding=None,
                ai_model="non-artificial",
                created_at=datetime.now(),
                is_still_valid=True
            )
            test_db.add(context)
            contexts.append(context)
        await test_db.flush()
        return contexts
    return _create_contexts
