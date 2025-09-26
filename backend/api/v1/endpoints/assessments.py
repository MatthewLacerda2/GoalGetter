from fastapi import APIRouter, HTTPException
from fastapi import Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
import logging
from backend.core.database import get_db
from backend.core.security import get_current_user
from backend.models.student import Student
from backend.models.subjective_question import SubjectiveQuestion
from backend.repositories.objective_repository import ObjectiveRepository
from backend.repositories.subjective_question_repository import SubjectiveQuestionRepository
from backend.schemas.assessment import SubjectiveQuestionsAssessmentResponse, SubjectiveQuestionEvaluationRequest, SubjectiveQuestionEvaluationResponse
from backend.services.gemini.assessment.assessment import gemini_generate_subjective_questions
from backend.utils.envs import NUM_QUESTIONS_PER_EVALUATION

logger = logging.getLogger(__name__)

router = APIRouter()

@router.post("", response_model=SubjectiveQuestionsAssessmentResponse, status_code=status.HTTP_201_CREATED)
async def take_subjective_questions_assessment(
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """
    Deliver a subjective questions assessment to the current user.

    It takes one from the DB or creates a new assessment for the user if none exists.
    """
    objective_repo = ObjectiveRepository(db)
    objective = await objective_repo.get_latest_by_goal_id(current_user.goal_id)

    sq_repo = SubjectiveQuestionRepository(db)
    subjective_question_results = await sq_repo.get_unanswered_or_wrong(objective.id, NUM_QUESTIONS_PER_EVALUATION)
    
    if len(subjective_question_results) > 5:
        return SubjectiveQuestionsAssessmentResponse(questions=[sq.question for sq in subjective_question_results])
    
    gemini_sq_questions = gemini_generate_subjective_questions(
        objective.name, objective.description, current_user.goal_name, NUM_QUESTIONS_PER_EVALUATION
    )
    
    for question in gemini_sq_questions.questions:
        sq = SubjectiveQuestion(
            objective_id=objective.id,
            question=question,
        )
        db.add(sq)
    
    await db.flush()
    await db.commit()
    
    stmt = select(SubjectiveQuestion).where(SubjectiveQuestion.objective_id == objective.id)
    result = await db.execute(stmt)
    db_sqs = result.scalars().all()
    
    return SubjectiveQuestionsAssessmentResponse(questions=[sq.question for sq in db_sqs])

@router.post("/evaluate/single_question", response_model=SubjectiveQuestionEvaluationResponse, status_code=status.HTTP_201_CREATED)
async def subjective_question_evaluation(
    request: SubjectiveQuestionEvaluationRequest,
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    from backend.services.gemini.assessment.single_question.single_question import gemini_generate_question_review
    from backend.utils.gemini.gemini_configs import get_gemini_embeddings
    
    sq_repo = SubjectiveQuestionRepository(db)
    su_question = await sq_repo.get_by_id(request.question_id)
    
    if su_question is None:
        HTTPException(status_code=400, detail="Question not found.")
    
    review = gemini_generate_question_review(request.question, request.student_answer)
    
    su_question.llm_approval = review.approval
    su_question.llm_evaluation = review.evaluation
    su_question.seconds_spent = request.seconds_spent
    su_question.llm_metacognition = review.metacognition
    su_question.llm_metacognition_embedding = get_gemini_embeddings(review.metacognition)
    
    await sq_repo.update(su_question)
    
    return SubjectiveQuestionEvaluationResponse(
        question_id=su_question.id,
        question=su_question.question,  # Fix: use .question instead of .id
        llm_evaluation=review.evaluation,
        llm_approval= review.approval
    )