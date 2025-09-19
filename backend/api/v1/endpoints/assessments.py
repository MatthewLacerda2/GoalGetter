from typing import List
from fastapi import APIRouter
from fastapi import HTTPException
from fastapi import Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
import logging
from backend.core.database import get_db
from backend.models.student import Student
from backend.models.objective import Objective
from backend.core.security import get_current_user
from backend.utils.envs import NUM_QUESTIONS_PER_EVALUATION
from backend.models.subjective_question import SubjectiveQuestion
from backend.schemas.assessment import SubjectiveQuestionsAssessmentResponse
from backend.utils.gemini.assessment.assessment import gemini_generate_subjective_questions

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
    stmt = select(Objective).where(Objective.goal_id == current_user.goal_id).order_by(Objective.last_updated_at.desc()).limit(1)
    result = await db.execute(stmt)
    objective = result.scalar_one_or_none()
    
    if not objective:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User did not finish the onboarding and does not have an objective.")
    
    stmt = select(SubjectiveQuestion).where(SubjectiveQuestion.objective_id == objective.id, SubjectiveQuestion.llm_approval == False)
    result = await db.execute(stmt)
    not_approved_question_results = result.scalars().all()
    
    for question in not_approved_question_results:
        sq = SubjectiveQuestion(
            objective_id=objective.id,
            question=question.question,
        )
        db.add(sq)
    
    stmt = select(SubjectiveQuestion).where(SubjectiveQuestion.objective_id == objective.id, SubjectiveQuestion.student_answer == None)
    result = await db.execute(stmt)
    unanswered_question_results = result.scalars().all()
    
    if unanswered_question_results and len(unanswered_question_results) > 5:
        return SubjectiveQuestionsAssessmentResponse(questions=[sq.question for sq in unanswered_question_results])
    else:
        
        gemini_sq_questions = gemini_generate_subjective_questions(
            objective.name, objective.description, current_user.goal.name, NUM_QUESTIONS_PER_EVALUATION
        )
        
        db_sqs: List[SubjectiveQuestion] = []
        
        for question in gemini_sq_questions.questions:
            sq = SubjectiveQuestion(
                objective_id=objective.id,
                question=question,
            )
            db.add(sq)
            db_sqs.append(sq)
        
        await db.flush()
        await db.commit()
        for sq in db_sqs:
            await db.refresh(sq)
        
        return SubjectiveQuestionsAssessmentResponse(questions=[sq.question for sq in db_sqs])