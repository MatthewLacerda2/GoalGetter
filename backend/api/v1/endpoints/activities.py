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
from backend.schemas.activity import MultipleChoiceActivityResponse
from backend.models.multiple_choice_question import MultipleChoiceQuestion
import uuid
from datetime import datetime

logger = logging.getLogger(__name__)

router = APIRouter()

@router.post("", response_model=MultipleChoiceActivityResponse, status_code=status.HTTP_201_CREATED)
async def take_multiple_choice_activity(
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """
    Deliver a multiple choice activity to the current user.

    It takes one from the DB or creates a new activity for the user if none exists.
    """
    stmt = select(Objective).where(Objective.goal_id == current_user.goal_id).order_by(Objective.last_updated_at.desc()).limit(1)
    result = await db.execute(stmt)
    objective = result.scalar_one_or_none()
    
    if not objective:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User did not finish the onboarding and does not have an objective.")
    
    stmt = select(MultipleChoiceQuestion).where(MultipleChoiceQuestion.objective_id == objective.id, MultipleChoiceQuestion.student_answer_index == None)
    result = await db.execute(stmt)
    multiple_choice_question_results = result.scalars().all()
    
    if multiple_choice_question_results:
        return MultipleChoiceActivityResponse(questions=multiple_choice_question_results)
    else:
        #TODO: have the AI create more questions
        #The right thing to do is to create a service that creates the questions, and then use it here
                        
        mcq = MultipleChoiceQuestion(
            objective_id=objective.id,
            question="What is the capital of France?",
            choices=["Paris", "London", "Berlin", "Madrid"],
            correct_answer_index=0,
            student_answer_index=None,
            seconds_spent=None,
            created_at=datetime.now(),
            last_updated_at=None
        )
        
        db.add(mcq)
        await db.flush()
        await db.commit()
        await db.refresh(mcq)
        
        return MultipleChoiceActivityResponse(questions=[mcq])
        