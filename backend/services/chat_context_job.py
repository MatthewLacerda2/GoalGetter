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
from backend.repositories.chat_message_repository import ChatMessageRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.ollama.chat_context.chat_context import ollama_chat_context
from backend.utils.gemini.gemini_configs import get_gemini_embeddings
from backend.utils.time_period import get_yesterday_date_range

logger = logging.getLogger(__name__)

async def run_chat_context_job():
    """
    Scheduled job that runs at 3:00 AM daily to generate student context from chat messages.
    
    For each eligible student (sent 3+ messages yesterday):
    1. Check if student sent at least 3 messages yesterday
    2. Gather all messages between the user and chatbot
    3. Generate context using AI
    4. Create StudentContext records for state/metacognition pairs
    """
    logger.info("Starting chat context generation job")
    
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
                            await generate_context_from_chat(student, student_db)
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
                f"Chat context generation job completed. "
                f"Processed: {processed_count}, Skipped: {skipped_count}, Errors: {error_count}"
            )
        except Exception as e:
            logger.error(f"Error in chat context generation job: {e}", exc_info=True)
            raise


async def should_generate_context(student: Student, db: AsyncSession) -> bool:
    """
    Check if a student is eligible for context generation based on:
    - Student must have sent at least 3 messages yesterday (where sender_id == student_id)
    
    Args:
        student: The student to check
        db: Database session
    
    Returns:
        True if student should have context generated, False otherwise
    """
    chat_repo = ChatMessageRepository(db)
    
    # Get yesterday's date range (00:00:00 to 23:59:59)
    yesterday_start, yesterday_end = get_yesterday_date_range()
    
    # Get all messages from yesterday
    yesterday_messages = await chat_repo.get_by_student_and_date_range(
        student.id,
        yesterday_start,
        yesterday_end
    )
    
    # Filter messages where sender_id == student_id (user messages only)
    user_messages = [msg for msg in yesterday_messages if msg.sender_id == student.id]
    
    if len(user_messages) < 3:
        logger.debug(
            f"Student {student.id} sent only {len(user_messages)} messages yesterday "
            f"(required: 3+)"
        )
        return False
    
    # Check if student has a current objective
    objective_repo = ObjectiveRepository(db)
    objective = await objective_repo.get_by_id(student.current_objective_id)
    
    if not objective:
        logger.debug(f"Student {student.id} has no current objective")
        return False
    
    return True


async def generate_context_from_chat(student: Student, db: AsyncSession):
    """
    Generate context from chat messages for a student.
    
    Args:
        student: The student to generate context for
        db: Database session
    """
    objective_repo = ObjectiveRepository(db)
    chat_repo = ChatMessageRepository(db)
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
    
    # Get all messages from yesterday (both user and bot messages for full conversation context)
    yesterday_messages = await chat_repo.get_by_student_and_date_range(
        student.id,
        yesterday_start,
        yesterday_end
    )
    
    if not yesterday_messages:
        logger.warning(f"Student {student.id} has no chat messages from yesterday")
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
    evaluation = ollama_chat_context(
        goal_name=goal.name or "",
        goal_description=goal.description or "",
        objective_name=objective.name,
        objective_description=objective.description,
        messages=yesterday_messages,
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
        
        # Create StudentContext with source="chat_context"
        student_context = StudentContext(
            student_id=student.id,
            goal_id=student.goal_id,
            objective_id=student.current_objective_id,
            source="chat_context",
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
        f"created {contexts_created} student contexts from {len(yesterday_messages)} chat messages from yesterday"
    )
