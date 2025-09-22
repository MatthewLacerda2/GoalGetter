import pytest
import numpy as np
from unittest.mock import patch
from backend.schemas.goal import GoalCreationFollowUpQuestionsResponse, GoalStudyPlanResponse

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

@pytest.fixture
def mock_gemini_embeddings():
    """Fixture to mock Gemini embeddings responses"""
    def mock_get_gemini_embeddings(text):
        return np.zeros(3072, dtype=np.float32)

    with patch('backend.api.v1.endpoints.onboarding.get_gemini_embeddings', side_effect=mock_get_gemini_embeddings) as mock:
        yield mock

@pytest.fixture
def mock_gemini_multiple_choice_questions():
    """Fixture to mock Gemini multiple choice questions responses"""
    def mock_generate_multiple_choice_questions(*args, **kwargs):
        from backend.services.gemini.activity.schema import GeminiMultipleChoiceQuestionsList, GeminiMultipleChoiceQuestion
        
        return GeminiMultipleChoiceQuestionsList(
            questions=[
                GeminiMultipleChoiceQuestion(
                    question=f"Sample question {i+1}: What is the correct way to print 'Hello World' in Python?",
                    choices=[
                        "print('Hello World')",
                        "echo('Hello World')",
                        "console.log('Hello World')",
                        "System.out.println('Hello World')"
                    ],
                    correct_answer_index=0,
                    xp = 10
                ) for i in range(10)
            ]
        )
    
    with patch('backend.api.v1.endpoints.activities.gemini_generate_multiple_choice_questions', side_effect=mock_generate_multiple_choice_questions) as mock:
        yield mock

@pytest.fixture
def mock_gemini_subjective_questions():
    """Fixture to mock Gemini subjective questions responses"""
    def mock_generate_subjective_questions(*args, **kwargs):
        from backend.utils.envs import NUM_QUESTIONS_PER_EVALUATION
        from backend.services.gemini.assessment.assessment import GeminiEvaluationQuestionsList
        
        questions = [f"Question {i+1}" for i in range(NUM_QUESTIONS_PER_EVALUATION)]
        
        return GeminiEvaluationQuestionsList(
            questions=questions
        )
    with patch('backend.api.v1.endpoints.assessments.gemini_generate_subjective_questions', side_effect=mock_generate_subjective_questions) as mock:
        yield mock