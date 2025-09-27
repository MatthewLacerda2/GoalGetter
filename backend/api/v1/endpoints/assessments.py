import logging
import asyncio
from datetime import datetime
from fastapi import Depends, status
from fastapi import APIRouter, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from backend.core.database import get_db
from backend.core.security import get_current_user
from backend.models.student import Student
from backend.models.subjective_question import SubjectiveQuestion
from backend.utils.gemini.gemini_configs import get_gemini_embeddings
from backend.repositories.objective_repository import ObjectiveRepository
from backend.repositories.subjective_question_repository import SubjectiveQuestionRepository
from backend.schemas.assessment import SubjectiveQuestionsAssessmentEvaluationRequest, SubjectiveQuestionsAssessmentEvaluationResponse
from backend.schemas.assessment import SubjectiveQuestionsAssessmentResponse, SubjectiveQuestionEvaluationRequest, SubjectiveQuestionEvaluationResponse

logger = logging.getLogger(__name__)

router = APIRouter()

async def save_evaluation_data(
    db: AsyncSession,
    current_user: Student,
    gemini_response,
    obj
):
    """Background task to save evaluation data to database."""
    from backend.models.objective_note import ObjectiveNote
    from backend.models.student_context import StudentContext
    from backend.repositories.objective_note_repository import ObjectiveNoteRepository
    from backend.repositories.student_context_repository import StudentContextRepository
    
    try:
        eval_embedding = get_gemini_embeddings(gemini_response.information)
        meta_embedding = get_gemini_embeddings(gemini_response.information)
        sd_ctx = StudentContext(
            student_id=current_user.id,
            goal_id=current_user.goal_id,
            objective_id=current_user.current_objective_id,
            state=gemini_response.evaluation,
            state_embedding=eval_embedding,
            metacognition=gemini_response.metacognition,
            metacognition_embedding=meta_embedding
        )
        ctxt_repo = StudentContextRepository(db)
        await ctxt_repo.create(sd_ctx)
        
        info_embedding = get_gemini_embeddings(gemini_response.information)
        info_note = ObjectiveNote(
            objective_id=obj.id,
            title=gemini_response.information[:32],
            info=gemini_response.information,
            info_embedding=info_embedding
        )
        notes_repo = ObjectiveNoteRepository(db)
        await notes_repo.create(info_note)
    except Exception as e:
        logger.error(f"Error saving evaluation data: {e}")

@router.post("", response_model=SubjectiveQuestionsAssessmentResponse, status_code=status.HTTP_201_CREATED)
async def take_subjective_questions_assessment(
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """
    Deliver a subjective questions assessment to the current user.

    It takes one from the DB or creates a new assessment for the user if none exists.
    """
    from backend.utils.envs import NUM_QUESTIONS_PER_EVALUATION
    from backend.services.gemini.assessment.assessment import gemini_generate_subjective_questions
    
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
    
    sq_repo = SubjectiveQuestionRepository(db)
    db_sqs = await sq_repo.get_by_objective_id(objective.id)
    
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
    
    su_question.seconds_spent = request.seconds_spent
    su_question.xp = 4
    su_question.last_updated_at = datetime.now()
    su_question.llm_approval = review.approval
    su_question.llm_evaluation = review.evaluation
    su_question.llm_metacognition = review.metacognition
    su_question.llm_metacognition_embedding = get_gemini_embeddings(review.metacognition)
    
    await sq_repo.update(su_question)
    
    return SubjectiveQuestionEvaluationResponse(
        question_id=su_question.id,
        question=su_question.question,
        llm_evaluation=review.evaluation,
        llm_approval= review.approval
    )

@router.post("/evaluate/overall", response_model=SubjectiveQuestionsAssessmentEvaluationResponse, status_code=status.HTTP_201_CREATED)
async def subjective_questions_overall_evaluation(
    request: SubjectiveQuestionsAssessmentEvaluationRequest,
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    from backend.services.gemini.assessment.overall_evaluation.overall_evaluation import gemini_subjective_evaluation_review
    
    sq_repo = SubjectiveQuestionRepository(db)
    
    db_questions = {}
    for question_id in request.questions_ids:
        db_question = await sq_repo.get_by_id(question_id)
        
        if db_question is None:
            raise HTTPException(status_code=404, detail=f"Question not found. Id: {question_id}")
        
        db_questions[question_id] = db_question
    
    obj_repo = ObjectiveRepository(db)
    obj = await obj_repo.get_by_id(current_user.current_objective_id)
    
    gemini_response = gemini_subjective_evaluation_review(
        obj.name, 
        obj.description, 
        [db_questions[q_id].question for q_id in request.questions_ids], 
        [db_questions[q_id].student_answer for q_id in request.questions_ids]
    )
    
    # Add background task to save data
    asyncio.create_task(save_evaluation_data(db, current_user, gemini_response, obj))
    
    response = SubjectiveQuestionsAssessmentEvaluationResponse(
        llm_evaluation=gemini_response.evaluation,
        llm_information=gemini_response.information,
        llm_metacognition=gemini_response.metacognition,
        is_approved=gemini_response.approval,
    )
    
    return response