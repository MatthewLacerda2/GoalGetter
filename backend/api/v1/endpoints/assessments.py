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

async def get_unanswered_or_wrong_questions(db: AsyncSession, objective_id: str):
    unanswered = SubjectiveQuestion.student_answer == None
    wrong = SubjectiveQuestion.llm_approval == False
    stmt = select(SubjectiveQuestion).where(
        SubjectiveQuestion.objective_id == objective_id,
        unanswered | wrong
    ).limit(NUM_QUESTIONS_PER_EVALUATION)
    result = await db.execute(stmt)
    return result.scalars().all()

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

    subjective_question_results = await get_unanswered_or_wrong_questions(db, objective.id)
    
    if len(subjective_question_results) > 5:
        return SubjectiveQuestionsAssessmentResponse(questions=[sq.question for sq in subjective_question_results])
    else:
        
        gemini_sq_questions = gemini_generate_subjective_questions(
            objective.name, objective.description, current_user.goal.name, NUM_QUESTIONS_PER_EVALUATION
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