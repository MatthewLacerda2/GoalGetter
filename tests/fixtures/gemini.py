import pytest
import numpy as np
from unittest.mock import patch, MagicMock
from backend.schemas.goal import GoalCreationFollowUpQuestionsResponse, GoalStudyPlanResponse
from backend.services.gemini.onboarding.schema import GeminiGoalValidation, GeminiFollowUpValidation

@pytest.fixture(scope="session", autouse=True)
def mock_gemini_client():
    """Global session-level fixture to mock google.genai.Client to prevent any real API calls."""
    mock_client_instance = MagicMock()
    
    # Configure embed_content to return zero embeddings by default
    mock_embed_response = MagicMock()
    mock_embedding = MagicMock()
    mock_embedding.values = [0.0] * 3072
    mock_embed_response.embeddings = [mock_embedding]
    mock_client_instance.models.embed_content.return_value = mock_embed_response
    
    # Configure generate_content to return a mock response that raises if called unmocked
    def mock_generate_content(*args, **kwargs):
        raise RuntimeError(
            "Attempted to make a real Gemini API generate_content call in a test without a mock! "
            "Please use mock_gemini_study_plan, mock_gemini_follow_up_questions, or other mocked fixtures."
        )
    mock_client_instance.models.generate_content.side_effect = mock_generate_content
    
    with patch('google.genai.Client', return_value=mock_client_instance) as mock_class:
        yield mock_class

@pytest.fixture
def mock_gemini_follow_up_questions():
    """Fixture to mock Gemini follow-up questions responses"""
    def mock_get_gemini_follow_up_questions(*args, **kwargs):
        return GoalCreationFollowUpQuestionsResponse(
            original_prompt="I want to learn Python. I just ran a 'hello world'. I wanna make apps",
            questions=["What is your current skill level in this area?", "How much time can you dedicate to this goal?", "What is your preferred learning style?", "Do you have any specific constraints or preferences?"]
        )

    with patch('backend.api.v1.endpoints.onboarding.get_gemini_follow_up_questions', side_effect=mock_get_gemini_follow_up_questions) as mock:
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
    with patch('backend.api.v1.endpoints.onboarding.get_gemini_study_plan', side_effect=mock_get_gemini_study_plan) as mock:
        yield mock

@pytest.fixture(autouse=True)
def mock_gemini_embeddings():
    """Fixture to mock Gemini embeddings responses. Uses autouse to prevent real API calls."""
    def mock_get_gemini_embeddings(text):
        return np.zeros(3072, dtype=np.float32)

    patch_targets = [
        'backend.utils.gemini.gemini_configs.get_gemini_embeddings',
        'backend.api.v1.endpoints.onboarding.get_gemini_embeddings',
        'backend.services.chat.chat_service.get_gemini_embeddings',
        'backend.services.account_creation_tasks.get_gemini_embeddings',
        'backend.services.chat_context_job.get_gemini_embeddings',
        'backend.services.gemini.resources.search_resources.get_gemini_embeddings',
        'backend.services.lesson_context_job.get_gemini_embeddings',
        'backend.services.mastery_evaluation_job.get_gemini_embeddings',
    ]

    patchers = [patch(target, side_effect=mock_get_gemini_embeddings) for target in patch_targets]
    mocks = [p.start() for p in patchers]
    yield mocks[0]
    for p in patchers:
        p.stop()

@pytest.fixture
def mock_gemini_multiple_choice_questions():
    """Fixture to mock Gemini multiple choice questions responses"""
    def mock_generate_multiple_choice_questions(*args, **kwargs):
        from backend.services.gemini.activity.schema import GeminiMultipleChoiceQuestionsResponse, GeminiMultipleChoiceQuestion
        from backend.utils.envs import NUM_QUESTIONS_PER_LESSON
        
        # Get num_questions from args (5th argument) or default to NUM_QUESTIONS_PER_LESSON
        num_questions = args[4] if len(args) > 4 else NUM_QUESTIONS_PER_LESSON
        
        return GeminiMultipleChoiceQuestionsResponse(
            questions=[
                GeminiMultipleChoiceQuestion(
                    question=f"Sample question {i+1}: What is the correct way to print 'Hello World' in Python?",
                    choices=[
                        "print('Hello World')",
                        "echo('Hello World')",
                        "console.log('Hello World')",
                        "System.out.println('Hello World')"
                    ],
                    correct_answer_index=0
                ) for i in range(num_questions)
            ],
            ai_model="test-model"
        )
    
    with patch('backend.api.v1.endpoints.activities.gemini_generate_multiple_choice_questions', side_effect=mock_generate_multiple_choice_questions) as mock:
        yield mock

@pytest.fixture
def mock_gemini_messages_generator():
    """Fixture to mock Gemini chat messages generator responses"""
    def mock_gemini_messages_generator(*args, **kwargs):
        from backend.services.gemini.chat.schema import GeminiChatResponse
        
        return GeminiChatResponse(
            messages=[
                "I can help you understand those SQLAlchemy concepts!",
                "Flush forces pending changes to be sent to the database immediately.",
                "Await is used for async operations - it waits for the operation to complete.",
                "Fresh reloads an object from the database, discarding any local changes."
            ]
        )
    
    with patch('backend.services.chat.chat_service.gemini_messages_generator', side_effect=mock_gemini_messages_generator) as mock:
        yield mock

@pytest.fixture
def mock_gemini_prompt_validation():
    """Fixture to mock Gemini prompt validation response"""
    def mock_get_prompt_validation(*args, **kwargs):
        return GeminiGoalValidation(
            makes_sense=True,
            is_harmless=True,
            is_achievable=True,
            reasoning="Mocked reasoning for validation",
        )

    with patch(
        'backend.api.v1.endpoints.onboarding.get_prompt_validation',
        side_effect=mock_get_prompt_validation,
    ) as mock:
        yield mock

@pytest.fixture
def mock_gemini_follow_up_validation():
    """Fixture to mock Gemini follow up validation response"""
    def mock_get_follow_up_validation(*args, **kwargs):
        return GeminiFollowUpValidation(
            has_enough_information=True,
            makes_sense=True,
            is_harmless=True,
            is_achievable=True,
            reasoning="mocked reasoning for validation",
        )

    with patch(
        'backend.api.v1.endpoints.onboarding.get_follow_up_validation',
        side_effect=mock_get_follow_up_validation,
    ) as mock:
        yield mock

