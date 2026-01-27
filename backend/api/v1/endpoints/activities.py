import asyncio
import logging
from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException
from fastapi import Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from backend.core.database import get_db, AsyncSessionLocal
from backend.models.streak_day import StreakDay
from backend.core.security import get_current_user
from backend.models.student import Student
from backend.models.multiple_choice_question import MultipleChoiceQuestion, MultipleChoiceAnswer
from backend.repositories.student_repository import StudentRepository
from backend.repositories.objective_repository import ObjectiveRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.repositories.multiple_choice_question_repository import MultipleChoiceQuestionRepository
from backend.repositories.streak_day_repository import StreakDayRepository
from backend.schemas.activity import MultipleChoiceActivityResponse, MultipleChoiceActivityEvaluationResponse
from backend.schemas.activity import MultipleChoiceActivityEvaluationRequest, MultipleChoiceQuestionResponse
from backend.services.gemini.activity.multiple_choices import gemini_generate_multiple_choice_questions
from backend.utils.envs import NUM_QUESTIONS_PER_LESSON

logger = logging.getLogger(__name__)

router = APIRouter()

async def create_lesson_questions_async(
    student_id: str,
    goal_id: str,
    num_questions: int,
    db: AsyncSession
) -> None:
    try:
        objective_repo = ObjectiveRepository(db)
        objective = await objective_repo.get_latest_by_goal_id(goal_id)
        
        objectives = await objective_repo.get_recent_by_goal_id(goal_id, limit=4)
        
        student_context_repo = StudentContextRepository(db)
        student_contexts = await student_context_repo.get_by_student_id(student_id, 5)
        
        contexts = [f"{sc.state}, {sc.metacognition}" for sc in student_contexts]
        
        gemini_mc_questions = gemini_generate_multiple_choice_questions(
            objective.name, objective.description, [o.name for o in objectives], contexts, num_questions
        )
        
        for question in gemini_mc_questions.questions:
            mcq = MultipleChoiceQuestion(
                objective_id=objective.id,
                question=question.question,
                option_a=question.choices[0],
                option_b=question.choices[1],
                option_c=question.choices[2],
                option_d=question.choices[3],
                correct_answer_index=question.correct_answer_index,
                ai_model=gemini_mc_questions.ai_model,
            )
            db.add(mcq)
        
        await db.commit()
    except Exception as e:
        logger.error(f"Error creating lesson questions: {e}", exc_info=True)
        await db.rollback()
        raise

@router.post("", response_model=MultipleChoiceActivityResponse, status_code=status.HTTP_201_CREATED)
async def take_multiple_choice_activity(
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    objective_repo = ObjectiveRepository(db)
    objective = await objective_repo.get_latest_by_goal_id(current_user.goal_id)
        
    mcq_repo = MultipleChoiceQuestionRepository(db)
    multiple_choice_question_results = await mcq_repo.get_unanswered_or_wrong(
        objective.id, current_user.id, NUM_QUESTIONS_PER_LESSON
    )
    
    # Create questions if we don't have enough
    if len(multiple_choice_question_results) < NUM_QUESTIONS_PER_LESSON:
        await create_lesson_questions_async(
            student_id=current_user.id,
            goal_id=current_user.goal_id,
            num_questions=NUM_QUESTIONS_PER_LESSON,
            db=db
        )
        # Fetch the newly created questions
        multiple_choice_question_results = await mcq_repo.get_unanswered_or_wrong(
            objective.id, current_user.id, NUM_QUESTIONS_PER_LESSON
        )
    
    question_responses = [
        MultipleChoiceQuestionResponse(
            id=str(q.id),
            question=q.question,
            choices=q.choices,
            correct_answer_index=q.correct_answer_index
        )
        for q in multiple_choice_question_results
    ]
    return MultipleChoiceActivityResponse(questions=question_responses)

@router.post("/evaluate", response_model=MultipleChoiceActivityEvaluationResponse, status_code=status.HTTP_201_CREATED)
async def take_multiple_choice_activity(
    request: MultipleChoiceActivityEvaluationRequest,
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """
    Takes the student's answers and informs the accuracy
    """
    from backend.repositories.multiple_choice_answer_repository import MultipleChoiceAnswerRepository
    
    if len(request.answers) < NUM_QUESTIONS_PER_LESSON:
        raise HTTPException(status_code= 400, detail = "Amount of questions was too low.")
    
    mcq_repo = MultipleChoiceQuestionRepository(db)
    answer_repo = MultipleChoiceAnswerRepository(db)
    xp_per_right_answer = 1 #TODO: make calculation
    
    db_questions: dict[str, MultipleChoiceQuestion] = {}
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
        
        is_correct = db_question.correct_answer_index == question.student_answer_index
        if is_correct:
            total_xp += xp_per_right_answer
            total_right_answers += 1
        
        # Always create a new answer to track answer history
        answer = MultipleChoiceAnswer(
            question_id=question.id,
            student_id=current_user.id,
            student_answer_index=question.student_answer_index,
            seconds_spent=question.seconds_spent,
            xp=xp_per_right_answer if is_correct else 0
        )
        await answer_repo.create(answer)
        
        total_seconds_spent += question.seconds_spent

    accuracy = (total_right_answers / len(request.answers)) * 100

    # Update or create streak day for today
    streak_repo = StreakDayRepository(db)
    current_date = datetime.now(timezone.utc)
    existing_streak_day = await streak_repo.get_by_student_id_and_date(current_user.id, current_date)
    
    if existing_streak_day:
        # Update existing streak day with additional XP
        existing_streak_day.xp += total_xp
        await streak_repo.update(existing_streak_day)
    else:
        # Create new streak day
        new_streak_day = StreakDay(
            student_id=current_user.id,
            date_time=current_date,
            xp=total_xp
        )
        await streak_repo.create(new_streak_day)

    student_repo = StudentRepository(db)
    await student_repo.increment_streak_days(current_user.id, total_xp)
    
    await db.commit()
    
    #TODO: kickoff lesson creation if there aren't enough questions

    return MultipleChoiceActivityEvaluationResponse(
        total_seconds_spent=total_seconds_spent,
        student_accuracy=accuracy,
        xp=total_xp
    )