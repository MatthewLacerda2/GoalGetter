import pytest
import numpy as np
from unittest.mock import patch
from backend.schemas.goal import GoalCreationFollowUpQuestionsResponse, GoalStudyPlanResponse
from backend.services.gemini.onboarding.schema import GeminiGoalValidation, GeminiFollowUpValidation

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

    with patch('backend.utils.gemini.gemini_configs.get_gemini_embeddings', side_effect=mock_get_gemini_embeddings) as mock1, \
         patch('backend.api.v1.endpoints.assessments.subjective_question_evaluation', side_effect=mock_get_gemini_embeddings) as mock2:
        yield mock1, mock2

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
def mock_gemini_subjective_questions():
    """Fixture to mock Gemini subjective questions responses"""
    def mock_generate_subjective_questions(*args, **kwargs):
        from backend.utils.envs import NUM_QUESTIONS_PER_EVALUATION
        from backend.services.gemini.assessment.assessment import GeminiEvaluationQuestionsResponse
        
        questions = [f"Question {i+1}" for i in range(NUM_QUESTIONS_PER_EVALUATION)]
        
        return GeminiEvaluationQuestionsResponse(
            questions=questions,
            ai_model="gemini-2.5-flash"
        )
    with patch('backend.services.gemini.assessment.assessment.gemini_generate_subjective_questions', side_effect=mock_generate_subjective_questions) as mock:
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
    
    with patch('backend.api.v1.endpoints.chat.gemini_messages_generator', side_effect=mock_gemini_messages_generator) as mock:
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

@pytest.fixture
def mock_gemini_single_question_review():
    """Fixture to mock Gemini single question review responses"""
    def mock_gemini_generate_question_review(*args, **kwargs):
        from backend.services.gemini.assessment.single_question.schema import GeminiSingleQuestionReview
        
        return GeminiSingleQuestionReview(
            approval=True,
            evaluation="The answer demonstrates a good understanding of diffusion models, though it could be more precise about the iterative denoising process.",
            metacognition="The student shows conceptual understanding but may benefit from more technical detail about the diffusion process."
        )
    
    with patch(
        'backend.services.gemini.assessment.single_question.single_question.gemini_generate_question_review',
        side_effect=mock_gemini_generate_question_review,
    ) as mock:
        yield mock

@pytest.fixture
def mock_subjective_question_repository():
    """Fixture to mock SubjectiveQuestionRepository.get_by_id"""
    from backend.models.subjective_question import SubjectiveQuestion
    
    def mock_get_by_id(question_id: str):
        # Return a mock question object
        question = SubjectiveQuestion()
        question.id = question_id
        question.question = "A Question"
        question.ai_model = "test-model"
        question.llm_approval = None
        question.llm_evaluation = None
        question.llm_metacognition = None
        question.seconds_spent = None
        question.llm_metacognition_embedding = None
        return question
    
    with patch(
        'backend.repositories.subjective_question_repository.SubjectiveQuestionRepository.get_by_id',
        side_effect=mock_get_by_id,
    ) as mock:
        yield mock

@pytest.fixture
def mock_gemini_overall_evaluation_review():
    """Fixture to mock Gemini overall evaluation review responses"""
    def mock_gemini_subjective_evaluation_review(*args, **kwargs):
        from backend.services.gemini.assessment.overall_evaluation.schema import GeminiSubjectiveEvaluationReviewResponse
        
        return GeminiSubjectiveEvaluationReviewResponse(
            evaluation="The student demonstrates good understanding of the concepts with clear explanations and practical examples.",
            information="The answers show comprehensive knowledge of the subject matter with accurate technical details.",
            metacognition="The student appears to have a solid grasp of the material and can apply concepts effectively.",
            approval=True,
            ai_model="gemini-2.5-flash"
        )
    
    with patch(
        'backend.services.gemini.assessment.overall_evaluation.overall_evaluation.gemini_subjective_evaluation_review',
        side_effect=mock_gemini_subjective_evaluation_review,
    ) as mock:
        yield mock