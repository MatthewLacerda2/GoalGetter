import logging
from typing import List
from datetime import datetime
from fastapi import APIRouter, HTTPException
from fastapi import Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from backend.core.database import get_db
from backend.core.security import get_current_user
from backend.models.student import Student
from backend.models.multiple_choice_question import MultipleChoiceQuestion
from backend.repositories.objective_repository import ObjectiveRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.repositories.multiple_choice_question_repository import MultipleChoiceQuestionRepository
from backend.schemas.activity import MultipleChoiceActivityResponse, MultipleChoiceActivityEvaluationResponse
from backend.schemas.activity import MultipleChoiceActivityEvaluationRequest, MultipleChoiceQuestionAnswer
from backend.services.gemini.activity.multiple_choices import gemini_generate_multiple_choice_questions
from backend.utils.envs import NUM_QUESTIONS_PER_LESSON

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
    objective_repo = ObjectiveRepository(db)
    objective = await objective_repo.get_latest_by_goal_id(current_user.goal_id)
        
    mcq_repo = MultipleChoiceQuestionRepository(db)
    multiple_choice_question_results = await mcq_repo.get_unanswered_or_wrong(objective.id, NUM_QUESTIONS_PER_LESSON)
    
    if len(multiple_choice_question_results) >= NUM_QUESTIONS_PER_LESSON:
        return MultipleChoiceActivityResponse(questions=multiple_choice_question_results)
    
    objective_repo = ObjectiveRepository(db)
    objectives = await objective_repo.get_recent_by_goal_id(current_user.goal_id, limit = 4)
    
    student_context_repo = StudentContextRepository(db)
    student_contexts = await student_context_repo.get_by_student_id(current_user.id, 5)
    
    contexts = [f"{sc.state}, {sc.metacognition}" for sc in student_contexts]
    
    #FIXME: o certo seria criar so o suficiente pra ter a licao
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

@router.post("/evaluate", response_model=MultipleChoiceActivityEvaluationResponse, status_code=status.HTTP_201_CREATED)
async def take_multiple_choice_activity(
    request: MultipleChoiceActivityEvaluationRequest,
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """
    Takes the student's answers and informs the accuracy
    """
    
    if len(request.answers) < NUM_QUESTIONS_PER_LESSON:
        raise HTTPException(status_code= 400, detail = "Amount of questions was too low.")
    
    mcq_repo = MultipleChoiceQuestionRepository(db)
    xp_per_right_answer = 1
    
    db_questions: List[MultipleChoiceQuestion] = []
    for question in request.answers:
        db_question: MultipleChoiceQuestion | None = await mcq_repo.get_by_id(question.id)
        
        if db_question is None:
            raise HTTPException(status_code=404, detail=f"Question not found. Id: {question.id}")
        
        db_questions[question.id] = db_question
    
    total_xp = 0
    total_right_answers = 0
    total_seconds_spent = 0
    
    for question in request.answers:
        db_question = db_questions[question.id]
        
        if db_question.correct_answer_index == question.student_answer_index:
            total_xp += xp_per_right_answer
            total_right_answers += 1
        
        db_question.student_answer_index = question.student_answer_index
        db_question.seconds_spent = question.seconds_spent
        db_question.last_updated_at = datetime.now()
        db_question.xp = xp_per_right_answer
        
        await mcq_repo.update(db_question)
        total_seconds_spent += question.seconds_spent

    accuracy = (total_right_answers / len(request.answers)) * 100

    return MultipleChoiceActivityEvaluationResponse(
        total_seconds_spent=total_seconds_spent,
        student_accuracy=accuracy,
        xp=total_xp
    )