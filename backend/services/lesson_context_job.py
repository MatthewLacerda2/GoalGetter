import logging
from datetime import datetime
from backend.core.database import AsyncSessionLocal
from backend.models.student import Student
from backend.models.goal import Goal
from backend.models.objective import Objective
from backend.models.student_context import StudentContext
from backend.repositories.objective_repository import ObjectiveRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.gemini.lesson_context.lesson_context import gemini_lesson_context
from backend.utils.gemini.gemini_configs import get_gemini_embeddings
from backend.utils.time_period import get_yesterday_date_range

logger = logging.getLogger(__name__)

async def run_lesson_context_job():
    logger.info("Starting lesson context generation job")
    
    async with AsyncSessionLocal() as db:
        try:
            objective_repo = ObjectiveRepository(db)
            
            # Get all goals
            from backend.repositories.goal_repository import GoalRepository
            goal_repo = GoalRepository(db)
            all_goals = await goal_repo.get_all()
            
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
                    # Get the student for this goal
                    from backend.repositories.student_repository import StudentRepository
                    student_repo = StudentRepository(db)
                    student = await student_repo.get_by_id(goal.student_id)
                    
                    if not student:
                        logger.warning(f"Goal {goal.id} has no associated student")
                        skipped_count += 1
                        continue
                    
                    # Process each objective in its own session to isolate failures
                    async with AsyncSessionLocal() as objective_db:
                        if await should_generate_context_for_objective(student, objective, objective_db):
                            await generate_context_from_lesson_for_objective(student, goal, objective, objective_db)
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
                f"Lesson context generation job completed. "
                f"Processed: {processed_count}, Skipped: {skipped_count}, Errors: {error_count}"
            )
        except Exception as e:
            logger.error(f"Error in lesson context generation job: {e}", exc_info=True)
            raise


async def should_generate_context_for_objective(student: Student, objective: Objective, db: AsyncSessionLocal) -> bool:
    yesterday_start, yesterday_end = get_yesterday_date_range()
    
    from backend.repositories.subjective_answer_repository import SubjectiveAnswerRepository
    from backend.repositories.multiple_choice_answer_repository import MultipleChoiceAnswerRepository
    
    subjective_repo = SubjectiveAnswerRepository(db)
    subjective_answers = await subjective_repo.get_by_student_objective_and_date_range(
        student.id, objective.id, yesterday_start, yesterday_end
    )
    has_subjective = len(subjective_answers) > 0
    
    mc_repo = MultipleChoiceAnswerRepository(db)
    mc_answers = await mc_repo.get_by_student_objective_and_date_range(
        student.id, objective.id, yesterday_start, yesterday_end
    )
    has_multiple_choice = len(mc_answers) > 0
    
    if not has_subjective and not has_multiple_choice:
        logger.debug(f"Objective {objective.id} has no answers from yesterday")
        return False
    
    return True


async def generate_context_from_lesson_for_objective(student: Student, goal: Goal, objective: "Objective", db: AsyncSessionLocal):
    context_repo = StudentContextRepository(db)
    
    yesterday_start, yesterday_end = get_yesterday_date_range()
    
    from backend.repositories.subjective_answer_repository import SubjectiveAnswerRepository
    from backend.repositories.multiple_choice_answer_repository import MultipleChoiceAnswerRepository
    
    subjective_repo = SubjectiveAnswerRepository(db)
    subjective_answers = await subjective_repo.get_by_student_objective_and_date_range(
        student.id, objective.id, yesterday_start, yesterday_end
    )
    
    mc_repo = MultipleChoiceAnswerRepository(db)
    mc_answers = await mc_repo.get_by_student_objective_and_date_range(
        student.id, objective.id, yesterday_start, yesterday_end
    )
    
    if not subjective_answers and not mc_answers:
        logger.warning(f"Objective {objective.id} has no answers from yesterday")
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
        logger.warning(f"Objective {objective.id} has no valid questions/answers to process")
        return
    
    # Get existing student contexts for this objective
    existing_contexts = await context_repo.get_by_student_and_objective(
        student.id,
        objective.id,
        limit=8
    )
    
    # Format student contexts as strings (combine state and metacognition)
    student_context_strings = [
        f"{sc.state}, {sc.metacognition}" 
        for sc in existing_contexts 
        if sc.state or sc.metacognition
    ] if existing_contexts else None
    
    # Generate context using AI
    evaluation = gemini_lesson_context(
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
            source="lesson_context",
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
        f"created {contexts_created} student contexts from {len(questions_answers)} questions/answers from yesterday"
    )
