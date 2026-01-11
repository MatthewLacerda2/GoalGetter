import logging
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, desc
from sqlalchemy.orm import joinedload
from backend.core.database import AsyncSessionLocal
from backend.models.student import Student
from backend.models.goal import Goal
from backend.models.student_context import StudentContext
from backend.models.multiple_choice_question import MultipleChoiceAnswer
from backend.models.subjective_question import SubjectiveAnswer
from backend.repositories.objective_repository import ObjectiveRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.ollama.lesson_context.lesson_context import ollama_lesson_context
from backend.utils.gemini.gemini_configs import get_gemini_embeddings
from backend.utils.time_period import get_yesterday_date_range

logger = logging.getLogger(__name__)

async def run_lesson_context_job():
    """
    Scheduled job that runs at 2:00 AM daily to generate student context from lesson answers.
    
    For each eligible student (has answers from yesterday):
    1. Check if student has answers (subjective or multiple-choice) from yesterday
    2. Gather all answers from yesterday
    3. Generate context using AI
    4. Create StudentContext records for state/metacognition pairs
    """
    logger.info("Starting lesson context generation job")
    
    async with AsyncSessionLocal() as db:
        try:
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
                        if await should_generate_context(student, student_db):
                            await generate_context_from_lesson(student, student_db)
                            processed_count += 1
                            logger.info(f"Successfully generated context for student {student.id}")
                        else:
                            skipped_count += 1
                except Exception as e:
                    error_count += 1
                    logger.error(f"Error generating context for student {student.id}: {e}", exc_info=True)
                    # Continue with next student
                    continue
            
            logger.info(
                f"Lesson context generation job completed. "
                f"Processed: {processed_count}, Skipped: {skipped_count}, Errors: {error_count}"
            )
        except Exception as e:
            logger.error(f"Error in lesson context generation job: {e}", exc_info=True)
            raise


async def should_generate_context(student: Student, db: AsyncSession) -> bool:
    """
    Check if a student is eligible for context generation based on:
    - Student has current_objective_id
    - Student has answers (subjective or multiple-choice) from yesterday
    
    Args:
        student: The student to check
        db: Database session
    
    Returns:
        True if student should have context generated, False otherwise
    """
    # Check if student has a current objective
    if not student.current_objective_id:
        logger.debug(f"Student {student.id} has no current objective")
        return False
    
    # Get yesterday's date range (00:00:00 to 23:59:59)
    yesterday_start, yesterday_end = get_yesterday_date_range()
    
    # Check for subjective answers from yesterday
    subjective_stmt = select(SubjectiveAnswer).where(
        and_(
            SubjectiveAnswer.student_id == student.id,
            SubjectiveAnswer.created_at >= yesterday_start,
            SubjectiveAnswer.created_at <= yesterday_end
        )
    ).limit(1)
    subjective_result = await db.execute(subjective_stmt)
    has_subjective = subjective_result.scalar_one_or_none() is not None
    
    # Check for multiple-choice answers from yesterday
    mc_stmt = select(MultipleChoiceAnswer).where(
        and_(
            MultipleChoiceAnswer.student_id == student.id,
            MultipleChoiceAnswer.created_at >= yesterday_start,
            MultipleChoiceAnswer.created_at <= yesterday_end
        )
    ).limit(1)
    mc_result = await db.execute(mc_stmt)
    has_multiple_choice = mc_result.scalar_one_or_none() is not None
    
    if not has_subjective and not has_multiple_choice:
        logger.debug(f"Student {student.id} has no answers from yesterday")
        return False
    
    return True


async def generate_context_from_lesson(student: Student, db: AsyncSession):
    """
    Generate context from lesson answers for a student.
    
    Args:
        student: The student to generate context for
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
    
    # Get yesterday's date range (00:00:00 to 23:59:59)
    yesterday_start, yesterday_end = get_yesterday_date_range()
    
    # Get all subjective answers from yesterday with questions joined
    subjective_stmt = select(SubjectiveAnswer).options(
        joinedload(SubjectiveAnswer.question)
    ).where(
        and_(
            SubjectiveAnswer.student_id == student.id,
            SubjectiveAnswer.created_at >= yesterday_start,
            SubjectiveAnswer.created_at <= yesterday_end
        )
    ).order_by(desc(SubjectiveAnswer.created_at))
    
    subjective_result = await db.execute(subjective_stmt)
    subjective_answers = list(subjective_result.unique().scalars().all())
    
    # Get all multiple-choice answers from yesterday with questions joined
    mc_stmt = select(MultipleChoiceAnswer).options(
        joinedload(MultipleChoiceAnswer.question)
    ).where(
        and_(
            MultipleChoiceAnswer.student_id == student.id,
            MultipleChoiceAnswer.created_at >= yesterday_start,
            MultipleChoiceAnswer.created_at <= yesterday_end
        )
    ).order_by(desc(MultipleChoiceAnswer.created_at))
    
    mc_result = await db.execute(mc_stmt)
    mc_answers = list(mc_result.unique().scalars().all())
    
    if not subjective_answers and not mc_answers:
        logger.warning(f"Student {student.id} has no answers from yesterday")
        return
    
    # Format answers: prioritize subjective first, then multiple-choice (limit 10 total)
    questions_answers: list[tuple[str, str]] = []
    
    # Add subjective answers first (up to 10)
    for answer in subjective_answers[:10]:
        if answer.question:
            questions_answers.append((answer.question.question, answer.student_answer))
    
    # Add multiple-choice answers if space remains (up to 10 total)
    remaining_slots = 10 - len(questions_answers)
    if remaining_slots > 0:
        for answer in mc_answers[:remaining_slots]:
            if answer.question:
                # Extract choice text from choices[student_answer_index]
                choices = answer.question.choices
                if 0 <= answer.student_answer_index < len(choices):
                    choice_text = choices[answer.student_answer_index]
                    questions_answers.append((answer.question.question, choice_text))
    
    if not questions_answers:
        logger.warning(f"Student {student.id} has no valid questions/answers to process")
        return
    
    # Get existing student contexts for the current objective
    existing_contexts = await context_repo.get_by_student_and_objective(
        student.id,
        student.current_objective_id,
        limit=8
    )
    
    # Format student contexts as strings (combine state and metacognition)
    student_context_strings = [
        f"{sc.state}, {sc.metacognition}" 
        for sc in existing_contexts 
        if sc.state or sc.metacognition
    ] if existing_contexts else None
    
    # Generate context using AI
    evaluation = ollama_lesson_context(
        goal_name=goal.name or "",
        goal_description=goal.description or "",
        objective_name=objective.name,
        objective_description=objective.description,
        questions_answers=questions_answers,
        student_context=student_context_strings
    )
    
    # Ensure arrays have same length (should already be handled in service, but double-check)
    state_array = evaluation.state if evaluation.state else []
    metacognition_array = evaluation.metacognition if evaluation.metacognition else []
    
    max_length = max(len(state_array), len(metacognition_array))
    state_array.extend([""] * (max_length - len(state_array)))
    metacognition_array.extend([""] * (max_length - len(metacognition_array)))
    
    # Create StudentContext records for each state/metacognition pair
    contexts_created = 0
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
        
        # Create StudentContext with source="lesson_context"
        student_context = StudentContext(
            student_id=student.id,
            goal_id=student.goal_id,
            objective_id=student.current_objective_id,
            source="lesson_context",
            state=state,
            metacognition=metacognition,
            state_embedding=state_embedding,
            metacognition_embedding=metacognition_embedding,
            is_still_valid=True,
            ai_model=evaluation.ai_model
        )
        
        await context_repo.create(student_context)
        contexts_created += 1
    
    await db.commit()
    
    logger.info(
        f"Generated context for student {student.id}: "
        f"created {contexts_created} student contexts from {len(questions_answers)} questions/answers from yesterday"
    )
