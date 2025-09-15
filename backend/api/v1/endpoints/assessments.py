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
from backend.schemas.assessment import SubjectiveQuestionsAssessmentResponse
from backend.models.subjective_question import SubjectiveQuestion

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
    
    stmt = select(SubjectiveQuestion).where(SubjectiveQuestion.objective_id == objective.id, SubjectiveQuestion.student_answer == None)
    result = await db.execute(stmt)
    subjective_question_results = result.scalars().all()
    
    if subjective_question_results:
        return SubjectiveQuestionsAssessmentResponse(questions=[sq.question for sq in subjective_question_results])
    else:
        #TODO: have the AI create more questions
        #The right thing to do is to create a service that creates the questions, and then use it here
                        
        sq = SubjectiveQuestion(
            objective_id=objective.id,
            question="What is the capital of France?",
        )
        
        db.add(sq)
        await db.flush()
        await db.commit()
        await db.refresh(sq)
        
        return SubjectiveQuestionsAssessmentResponse(questions=[sq.question])