import logging
from typing import List
from fastapi import APIRouter
from fastapi import HTTPException
from fastapi import Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from backend.core.database import get_db
from backend.core.security import get_current_user
from backend.utils.envs import NUM_QUESTIONS_PER_LESSON
from backend.schemas.activity import MultipleChoiceActivityResponse
from backend.models.student import Student
from backend.models.objective import Objective
from backend.models.student_context import StudentContext
from backend.models.multiple_choice_question import MultipleChoiceQuestion
from backend.services.gemini.activity.multiple_choices import gemini_generate_multiple_choice_questions

logger = logging.getLogger(__name__)

router = APIRouter()

async def get_unanswered_or_wrong_questions(db: AsyncSession, objective_id: str):
    unanswered = MultipleChoiceQuestion.student_answer_index == None
    wrong = MultipleChoiceQuestion.student_answer_index != MultipleChoiceQuestion.correct_answer_index
    stmt = select(MultipleChoiceQuestion).where(
        MultipleChoiceQuestion.objective_id == objective_id,
        unanswered | wrong
    ).limit(NUM_QUESTIONS_PER_LESSON)
    result = await db.execute(stmt)
    return result.scalars().all()

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
    
    multiple_choice_question_results = await get_unanswered_or_wrong_questions(db, objective.id)
    
    if len(multiple_choice_question_results) > 5:
        return MultipleChoiceActivityResponse(questions=multiple_choice_question_results)
    else:
        
        stmt = select(Objective).where(Objective.goal_id == current_user.goal_id).order_by(Objective.last_updated_at.desc()).limit(4)
        result = await db.execute(stmt)
        objectives = result.scalars().all()
        
        stmt = select(StudentContext).where(StudentContext.student_id == current_user.id, StudentContext.is_still_valid == True).order_by(StudentContext.created_at.desc()).limit(5)
        result = await db.execute(stmt)
        student_contexts = result.scalars().all()
        
        contexts = [f"{sc.state}, {sc.metacognition}" for sc in student_contexts]
        
        gemini_mc_questions = gemini_generate_multiple_choice_questions(
            objective.name, objective.description, [o.name for o in objectives], contexts, NUM_QUESTIONS_PER_LESSON
        )
        
        db_mcqs: List[MultipleChoiceQuestion] = []
        
        for question in gemini_mc_questions.questions:
            mcq = MultipleChoiceQuestion(
                objective_id=objective.id,
                question=question.question,
                choices=question.choices,
                correct_answer_index=question.correct_answer_index,
            )
            db.add(mcq)
            db_mcqs.append(mcq)
        
        await db.flush()
        await db.commit()
        for mcq in db_mcqs:
            await db.refresh(mcq)
        
        return MultipleChoiceActivityResponse(questions=[mcq for mcq in db_mcqs])