import logging
from datetime import datetime, timedelta, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from backend.core.database import AsyncSessionLocal
from backend.models.student import Student
from backend.models.goal import Goal
from backend.models.objective import Objective
from backend.models.student_context import StudentContext
from backend.repositories.objective_repository import ObjectiveRepository
from backend.repositories.streak_day_repository import StreakDayRepository
from backend.repositories.multiple_choice_answer_repository import MultipleChoiceAnswerRepository
from backend.repositories.subjective_answer_repository import SubjectiveAnswerRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.gemini.progress_evaluation.progress_evaluation import gemini_progress_evaluation
from backend.utils.gemini.gemini_configs import get_gemini_embeddings
from backend.utils.time_period import get_yesterday_date_range

logger = logging.getLogger(__name__)

async def run_mastery_evaluation_job():
    logger.info("Starting mastery evaluation job")
    
    async with AsyncSessionLocal() as db:
        try:
            objective_repo = ObjectiveRepository(db)
            
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
                    student_stmt = select(Student).where(Student.id == goal.student_id)
                    student_result = await db.execute(student_stmt)
                    student = student_result.scalar_one_or_none()
                    
                    if not student:
                        logger.warning(f"Goal {goal.id} has no associated student")
                        skipped_count += 1
                        continue
                    
                    async with AsyncSessionLocal() as objective_db:
                        if await should_evaluate_objective(student, objective, objective_db):
                            await evaluate_objective_progress(student, goal, objective, objective_db)
                            processed_count += 1
                            logger.info(f"Successfully evaluated objective {objective.id}")
                        else:
                            skipped_count += 1
                except Exception as e:
                    error_count += 1
                    logger.error(f"Error evaluating objective {objective.id}: {e}", exc_info=True)
                    continue
            
            logger.info(
                f"Mastery evaluation job completed. "
                f"Processed: {processed_count}, Skipped: {skipped_count}, Errors: {error_count}"
            )
        except Exception as e:
            logger.error(f"Error in mastery evaluation job: {e}", exc_info=True)
            raise


async def should_evaluate_objective(student: Student, objective: "Objective", db: AsyncSession) -> bool:
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
    
    #if sq_accuracy < 80.0:
        #logger.debug(f"Student {student.id} failed subjective accuracy check: {sq_accuracy}% < 80%")
        #return False
    
    # Check 3: Objective update timing (must be >= 7 days ago)
    seven_days_ago = datetime.now(timezone.utc) - timedelta(days=7)
    
    # objective.last_updated_at is timezone-aware, so compare directly
    if objective.last_updated_at > seven_days_ago:
        logger.debug(
            f"Objective {objective.id} updated too recently: "
            f"{objective.last_updated_at} > {seven_days_ago}"
        )
        return False
    
    return True


async def evaluate_objective_progress(student: Student, goal: Goal, objective: Objective, db: AsyncSession):
    """ Evaluate an objective's progress and update it. """
    context_repo = StudentContextRepository(db)
    
    # Get latest 8 valid student contexts for this objective, ordered by created_at DESC
    contexts = await context_repo.get_latest_for_evaluation(
        student.id,
        objective.id,
        limit=8
    )
    
    # Generate progress evaluation using AI
    evaluation = gemini_progress_evaluation(
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
        
        if not state and not metacognition:
            continue
        
        student_context = StudentContext(
            student_id=student.id,
            goal_id=goal.id,
            objective_id=objective.id,
            source="progress_evaluation",
            state=state,
            metacognition=metacognition,
            state_embedding=get_gemini_embeddings(state) if state else None,
            metacognition_embedding=get_gemini_embeddings(metacognition) if metacognition else None,
            is_still_valid=True,
            ai_model=evaluation.ai_model
        )
        
        await context_repo.create(student_context)
    
    # Update objective percentage_completed and last_updated_at
    objective_repo = ObjectiveRepository(db)
    objective.percentage_completed = evaluation.percentage_completed
    objective.last_updated_at = datetime.now(timezone.utc)
    
    await objective_repo.update(objective)
    await db.commit()
    
    logger.info(
        f"Updated objective {objective.id}: "
        f"percentage_completed = {evaluation.percentage_completed}%, "
        f"created {max_length} student contexts"
    )
