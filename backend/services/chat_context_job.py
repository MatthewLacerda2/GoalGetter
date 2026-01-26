import logging
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from backend.core.database import AsyncSessionLocal
from backend.models.student import Student
from backend.models.goal import Goal
from backend.models.objective import Objective
from backend.models.student_context import StudentContext
from backend.repositories.objective_repository import ObjectiveRepository
from backend.repositories.chat_message_repository import ChatMessageRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.gemini.chat_context.chat_context import gemini_chat_context
from backend.utils.gemini.gemini_configs import get_gemini_embeddings
from backend.utils.time_period import get_yesterday_date_range

logger = logging.getLogger(__name__)

async def run_chat_context_job():
    logger.info("Starting chat context generation job")
    
    async with AsyncSessionLocal() as db:
        try:
            # Get all active objectives (latest objective for each goal, most recent by created_at)
            # For each goal, get the latest objective
            objective_repo = ObjectiveRepository(db)
            
            # Get all goals
            goals_stmt = select(Goal)
            goals_result = await db.execute(goals_stmt)
            all_goals = goals_result.scalars().all()
            
            active_objectives = []
            for goal in all_goals:
                latest_objective = await objective_repo.get_latest_by_goal_id(goal.id)
                if latest_objective:
                    active_objectives.append((goal, latest_objective))
            
            logger.info(f"Found {len(active_objectives)} active objectives to evaluate")
            
            processed_count = 0
            skipped_count = 0
            error_count = 0
            
            for goal, objective in active_objectives:
                try:
                    # Get the student for this goal
                    student_stmt = select(Student).where(Student.id == goal.student_id)
                    student_result = await db.execute(student_stmt)
                    student = student_result.scalar_one_or_none()
                    
                    if not student:
                        logger.warning(f"Goal {goal.id} has no associated student")
                        skipped_count += 1
                        continue
                    
                    # Process each objective in its own session to isolate failures
                    async with AsyncSessionLocal() as objective_db:
                        if await should_generate_context_for_objective(student, objective, objective_db):
                            await generate_context_from_chat_for_objective(student, goal, objective, objective_db)
                            processed_count += 1
                            logger.info(f"Successfully generated context for objective {objective.id}")
                        else:
                            skipped_count += 1
                except Exception as e:
                    error_count += 1
                    logger.error(f"Error generating context for objective {objective.id}: {e}", exc_info=True)
                    # Continue with next objective
                    continue
            
            logger.info(
                f"Chat context generation job completed. "
                f"Processed: {processed_count}, Skipped: {skipped_count}, Errors: {error_count}"
            )
        except Exception as e:
            logger.error(f"Error in chat context generation job: {e}", exc_info=True)
            raise


async def should_generate_context_for_objective(student: Student, objective: Objective, db: AsyncSession) -> bool:
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
            f"(required: 3+) for objective {objective.id}"
        )
        return False
    
    return True


async def generate_context_from_chat_for_objective(student: Student, goal: Goal, objective: "Objective", db: AsyncSession):
    chat_repo = ChatMessageRepository(db)
    context_repo = StudentContextRepository(db)
    
    yesterday_start, yesterday_end = get_yesterday_date_range()
    
    yesterday_messages = await chat_repo.get_by_student_and_date_range(
        student.id,
        yesterday_start,
        yesterday_end
    )
    
    if not yesterday_messages:
        return
    
    existing_contexts = await context_repo.get_by_student_and_objective(
        student.id,
        objective.id,
        limit=8
    )
    
    student_context_strings = [
        f"{sc.state}, {sc.metacognition}" 
        for sc in existing_contexts 
        if sc.state or sc.metacognition
    ] if existing_contexts else None
    
    evaluation = gemini_chat_context(
        goal_name=goal.name or "",
        goal_description=goal.description or "",
        objective_name=objective.name,
        objective_description=objective.description,
        messages=yesterday_messages,
        student_context=student_context_strings
    )
    
    state_array = evaluation.state if evaluation.state else []
    metacognition_array = evaluation.metacognition if evaluation.metacognition else []
    
    max_length = max(len(state_array), len(metacognition_array))
    state_array.extend([""] * (max_length - len(state_array)))
    metacognition_array.extend([""] * (max_length - len(metacognition_array)))
    
    contexts_created = 0
    for i in range(max_length):
        state = state_array[i] if i < len(state_array) else ""
        metacognition = metacognition_array[i] if i < len(metacognition_array) else ""
        
        if not state and not metacognition:
            continue

        is_duplicate = await context_repo.is_too_similar(
            student_id=student.id, 
            state=state, 
            metacognition=metacognition
        )
        
        if is_duplicate:
            continue
        
        student_context = StudentContext(
            student_id=student.id,
            goal_id=goal.id,
            objective_id=objective.id,
            source="chat_context",
            state=state,
            metacognition=metacognition,
            state_embedding=get_gemini_embeddings(state) if state else None,
            metacognition_embedding=get_gemini_embeddings(metacognition) if metacognition else None,
            is_still_valid=True,
            ai_model=evaluation.ai_model
        )
        
        await context_repo.create(student_context)
        contexts_created += 1
    
    await db.commit()
    
    logger.info(
        f"Generated context for objective {objective.id}: "
        f"created {contexts_created} student contexts from {len(yesterday_messages)} chat messages from yesterday"
    )
