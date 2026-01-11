import logging
from datetime import datetime, timedelta, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from backend.core.database import AsyncSessionLocal
from backend.models.student import Student
from backend.models.goal import Goal
from backend.models.student_context import StudentContext
from backend.repositories.student_repository import StudentRepository
from backend.repositories.objective_repository import ObjectiveRepository
from backend.repositories.streak_day_repository import StreakDayRepository
from backend.repositories.multiple_choice_answer_repository import MultipleChoiceAnswerRepository
from backend.repositories.subjective_answer_repository import SubjectiveAnswerRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.ollama.progress_evaluation.progress_evaluation import ollama_progress_evaluation
from backend.utils.gemini.gemini_configs import get_gemini_embeddings
from backend.utils.time_period import get_yesterday_date_range

logger = logging.getLogger(__name__)

async def run_mastery_evaluation_job():
    """
    Scheduled job that runs at 5:00 AM daily to evaluate student mastery.
    
    For each eligible student:
    1. Check streak day eligibility (yesterday OR 3+ in last 7 days)
    2. Check accuracy requirements (80%+ for last 30 MCQs and 10 subjective questions)
    3. Check objective update timing (must be updated >= 7 days ago)
    4. Generate progress evaluation using AI
    5. Create StudentContext records for state/metacognition pairs
    6. Update objective percentage_completed and last_updated_at
    """
    logger.info("Starting mastery evaluation job")
    
    async with AsyncSessionLocal() as db:
        try:
            student_repo = StudentRepository(db)
            objective_repo = ObjectiveRepository(db)
            
            # Get all students
            stmt = select(Student)
            result = await db.execute(stmt)
            all_students = result.scalars().all()
            
            logger.info(f"Found {len(all_students)} students to evaluate")
            
            processed_count = 0
            skipped_count = 0
            error_count = 0
            
            for student in all_students:
                try:
                    # Process each student in their own session to isolate failures
                    async with AsyncSessionLocal() as student_db:
                        if await should_evaluate_student(student, student_db):
                            await evaluate_student_progress(student, student_db)
                            processed_count += 1
                            logger.info(f"Successfully evaluated student {student.id}")
                        else:
                            skipped_count += 1
                except Exception as e:
                    error_count += 1
                    logger.error(f"Error evaluating student {student.id}: {e}", exc_info=True)
                    # Continue with next student
                    continue
            
            logger.info(
                f"Mastery evaluation job completed. "
                f"Processed: {processed_count}, Skipped: {skipped_count}, Errors: {error_count}"
            )
        except Exception as e:
            logger.error(f"Error in mastery evaluation job: {e}", exc_info=True)
            raise


async def should_evaluate_student(student: Student, db: AsyncSession) -> bool:
    """
    Check if a student is eligible for evaluation based on:
    1. Streak day requirements (yesterday OR 3+ in last 7 days)
    2. Accuracy requirements (80%+ for MCQs and subjective questions)
    3. Objective update timing (must be >= 7 days ago)
    
    Returns:
        True if student should be evaluated, False otherwise
    """
    # Get current objective
    objective_repo = ObjectiveRepository(db)
    objective = await objective_repo.get_by_id(student.current_objective_id)
    
    if not objective:
        logger.warning(f"Student {student.id} has no current objective")
        return False
    
    # Check 1: Streak day eligibility
    # Student must have streak day yesterday OR 3+ streak days in last 7 days
    streak_repo = StreakDayRepository(db)
    yesterday_start, _ = get_yesterday_date_range()
    
    yesterday_streak = await streak_repo.get_by_student_id_and_date(student.id, yesterday_start)
    
    if not yesterday_streak:
        # Check if student has 3+ streak days in last 7 days
        last_7_days = await streak_repo.get_by_student_id_and_days(student.id, 7)
        if len(last_7_days) < 3:
            logger.debug(f"Student {student.id} failed streak check (no yesterday, < 3 in last 7 days)")
            return False
    
    # Check 2: Accuracy requirements
    mcq_repo = MultipleChoiceAnswerRepository(db)
    sq_repo = SubjectiveAnswerRepository(db)
    
    _, mcq_accuracy = await mcq_repo.get_latest_with_accuracy(student.id, limit=30)
    _, sq_accuracy = await sq_repo.get_latest_with_accuracy(student.id, limit=10)
    
    if mcq_accuracy < 80.0:
        logger.debug(f"Student {student.id} failed MCQ accuracy check: {mcq_accuracy}% < 80%")
        return False
    
    if sq_accuracy < 80.0:
        logger.debug(f"Student {student.id} failed subjective accuracy check: {sq_accuracy}% < 80%")
        return False
    
    # Check 3: Objective update timing (must be >= 7 days ago)
    seven_days_ago = datetime.now(timezone.utc) - timedelta(days=7)
    
    # objective.last_updated_at is timezone-aware, so compare directly
    if objective.last_updated_at > seven_days_ago:
        logger.debug(
            f"Student {student.id} objective updated too recently: "
            f"{objective.last_updated_at} > {seven_days_ago}"
        )
        return False
    
    return True


async def evaluate_student_progress(student: Student, db: AsyncSession):
    """
    Evaluate a student's progress and update their objective.
    
    Args:
        student: The student to evaluate
        db: Database session
    """
    objective_repo = ObjectiveRepository(db)
    context_repo = StudentContextRepository(db)
    
    # Get goal using select statement
    goal_stmt = select(Goal).where(Goal.id == student.goal_id)
    goal_result = await db.execute(goal_stmt)
    goal = goal_result.scalar_one_or_none()
    
    objective = await objective_repo.get_by_id(student.current_objective_id)
    
    if not goal or not objective:
        raise ValueError(f"Student {student.id} missing goal or objective")
    
    # Get latest 8 valid student contexts, ordered by objective (current first), then created_at DESC
    contexts = await context_repo.get_latest_for_evaluation(
        student.id,
        student.current_objective_id,
        limit=8
    )
    
    # Generate progress evaluation using AI
    evaluation = ollama_progress_evaluation(
        goal_name=goal.name or "",
        goal_description=goal.description or "",
        objective_name=objective.name,
        objective_description=objective.description,
        percentage_completed=objective.percentage_completed,
        contexts=contexts
    )
    
    # Ensure arrays have same length (should already be handled in service, but double-check)
    state_array = evaluation.state if evaluation.state else []
    metacognition_array = evaluation.metacognition if evaluation.metacognition else []
    
    max_length = max(len(state_array), len(metacognition_array))
    state_array.extend([""] * (max_length - len(state_array)))
    metacognition_array.extend([""] * (max_length - len(metacognition_array)))
    
    # Create StudentContext records for each state/metacognition pair
    for i in range(max_length):
        state = state_array[i] if i < len(state_array) else ""
        metacognition = metacognition_array[i] if i < len(metacognition_array) else ""
        
        # Skip if both are empty
        if not state and not metacognition:
            continue
        
        # Generate embeddings for non-empty strings
        state_embedding = None
        metacognition_embedding = None
        
        if state:
            try:
                state_embedding = get_gemini_embeddings(state)
            except Exception as e:
                logger.warning(f"Error generating state embedding: {e}")
        
        if metacognition:
            try:
                metacognition_embedding = get_gemini_embeddings(metacognition)
            except Exception as e:
                logger.warning(f"Error generating metacognition embedding: {e}")
        
        # Create StudentContext
        student_context = StudentContext(
            student_id=student.id,
            goal_id=student.goal_id,
            objective_id=student.current_objective_id,
            source="progress_evaluation",
            state=state,
            metacognition=metacognition,
            state_embedding=state_embedding,
            metacognition_embedding=metacognition_embedding,
            is_still_valid=True,
            ai_model=evaluation.ai_model
        )
        
        await context_repo.create(student_context)
    
    # Update objective percentage_completed and last_updated_at
    objective.percentage_completed = evaluation.percentage_completed
    objective.last_updated_at = datetime.now(timezone.utc)
    
    await objective_repo.update(objective)
    await db.commit()
    
    logger.info(
        f"Updated objective {objective.id} for student {student.id}: "
        f"percentage_completed = {evaluation.percentage_completed}%, "
        f"created {max_length} student contexts"
    )
