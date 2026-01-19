import logging
import asyncio
from sqlalchemy import select
from sqlalchemy.orm import joinedload
from backend.core.database import AsyncSessionLocal
from backend.models.objective import Objective
from backend.models.goal import Goal
from backend.services.content_check import objective_missing_content
from backend.services.account_creation_tasks import account_creation_tasks

logger = logging.getLogger(__name__)


async def run_startup_content_creation():
    """
    Startup task that finds all objectives missing content and creates it.
    
    This runs as a background task after startup to:
    - Find objectives missing MCQs, notes, resources, or student context
    - Call account_creation_tasks to generate the missing content
    - Handle errors gracefully (logs but doesn't fail startup)
    """
    logger.info("Starting startup content creation task")
    
    async with AsyncSessionLocal() as db:
        try:
            # Query all objectives with their goals
            # We need goal info (id, name, description, student_id) for account_creation_tasks
            objectives_stmt = select(Objective).options(
                joinedload(Objective.goal)
            )
            objectives_result = await db.execute(objectives_stmt)
            all_objectives = objectives_result.unique().scalars().all()
            
            logger.info(f"Found {len(all_objectives)} objectives to check")
            
            processed_count = 0
            created_count = 0
            skipped_count = 0
            error_count = 0
            
            for objective in all_objectives:
                try:
                    # Get goal info (already loaded via joinedload)
                    goal = objective.goal
                    if not goal:
                        logger.warning(f"Objective {objective.id} has no associated goal, skipping")
                        skipped_count += 1
                        continue
                    
                    # Get student_id from goal
                    student_id = goal.student_id
                    if not student_id:
                        logger.warning(f"Goal {goal.id} has no student_id, skipping objective {objective.id}")
                        skipped_count += 1
                        continue
                    
                    # Check if content is missing
                    is_missing = await objective_missing_content(
                        objective_id=str(objective.id),
                        goal_id=str(goal.id),
                        student_id=str(student_id),
                        db=db
                    )
                    
                    if not is_missing:
                        # Content exists, skip
                        skipped_count += 1
                        continue
                    
                    # Content is missing, create it
                    logger.info(
                        f"Objective {objective.id} (Goal: {goal.id}) missing content, "
                        f"creating content..."
                    )
                    
                    # Extract values to avoid async ORM access issues
                    goal_name = goal.name
                    goal_description = goal.description
                    objective_name = objective.name
                    objective_description = objective.description
                    
                    # Use a new database session for account_creation_tasks to avoid session conflicts
                    async with AsyncSessionLocal() as task_db:
                        try:
                            await account_creation_tasks(
                                student_id=str(student_id),
                                goal_id=str(goal.id),
                                goal_name=goal_name,
                                goal_description=goal_description,
                                objective_id=str(objective.id),
                                objective_name=objective_name,
                                objective_description=objective_description,
                                db=task_db,
                                onboarding_prompt=None,
                                questions_answers=None
                            )
                            created_count += 1
                            logger.info(
                                f"Successfully created content for objective {objective.id}"
                            )
                        except Exception as task_error:
                            error_count += 1
                            logger.error(
                                f"Error creating content for objective {objective.id}: {task_error}",
                                exc_info=True
                            )
                    
                    processed_count += 1
                    
                except Exception as e:
                    error_count += 1
                    logger.error(
                        f"Error processing objective {objective.id}: {e}",
                        exc_info=True
                    )
            
            logger.info(
                f"Startup content creation task completed: "
                f"Processed={processed_count}, Created={created_count}, "
                f"Skipped={skipped_count}, Errors={error_count}"
            )
            
        except Exception as e:
            logger.error(f"Error in startup content creation task: {e}", exc_info=True)
