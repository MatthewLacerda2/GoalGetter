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

