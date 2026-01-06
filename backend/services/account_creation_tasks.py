import logging
from sqlalchemy.ext.asyncio import AsyncSession
from backend.models.objective import Objective
from backend.models.goal import Goal
from backend.models.student import Student
from backend.utils.envs import NUM_QUESTIONS_PER_LESSON
from backend.services.gemini.activity.multiple_choices import gemini_generate_multiple_choice_questions
from backend.models.multiple_choice_question import MultipleChoiceQuestion
from backend.services.gemini.objective_notes.objective_notes import gemini_define_objective_notes
from backend.models.objective_note import ObjectiveNote
from backend.services.gemini.resources.search_resources import search_resources
from backend.repositories.resource_repository import ResourceRepository
from backend.services.gemini.student_context.student_context import gemini_generate_student_context
from backend.models.student_context import StudentContext
from backend.repositories.student_context_repository import StudentContextRepository
from backend.utils.gemini.gemini_configs import get_gemini_embeddings

logger = logging.getLogger(__name__)

async def account_creation_tasks(
    student: Student,
    goal: Goal,
    objective: Objective,
    db: AsyncSession,
    onboarding_prompt: str | None = None,
    questions_answers: list[tuple[str, str]] | None = None
) -> None:
    """
    Async function to create all initial data for a new student account.
    
    This includes:
    - Generating multiple choice questions (4 batches)
    - Creating objective notes
    - Searching and saving resources
    - Creating initial student context
    """
    try:
        # Generate MCQs in 4 batches
        for i in range(4):
            await create_mcqs_async(objective, db)
        
        # Create objective notes
        await create_notes_async(objective.name, objective.description, objective.id, db)
        
        # Search and save resources
        await create_resources_async(goal, objective, db, onboarding_prompt, questions_answers)
        
        # Create initial student context
        await create_student_context_async(
            student, goal, objective, db, onboarding_prompt, questions_answers
        )
        
    except Exception as e:
        logger.error(f"Error in account_creation_tasks: {e}", exc_info=True)
        raise

async def create_mcqs_async(objective: Objective, db: AsyncSession) -> None:
    """Create a batch of multiple choice questions using Gemini"""
    try:
        gemini_mc_questions = gemini_generate_multiple_choice_questions(
            objective_name=objective.name,
            objective_description=objective.description,
            previous_objectives=["This is the student's first objective ever"],
            informations=["No relevant information to add"],
            num_questions=NUM_QUESTIONS_PER_LESSON
        )
        
        for question in gemini_mc_questions.questions:
            # Map choices list to individual option fields
            if len(question.choices) < 4:
                logger.warning(f"Question has fewer than 4 choices: {question.question}")
                continue
                
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
        logger.error(f"Error creating MCQs: {e}", exc_info=True)
        await db.rollback()
        raise

async def create_notes_async(obj_name: str, obj_desc: str, obj_id: str, db: AsyncSession):
    """Create objective notes using Gemini"""
    try:
        gemini_notes = gemini_define_objective_notes(obj_name, obj_desc)
        
        for note in gemini_notes.notes:
            objective_note = ObjectiveNote(
                objective_id=obj_id,
                title=note.title,
                info=note.info
            )
            db.add(objective_note)
        
        await db.commit()
    except Exception as e:
        logger.error(f"Error creating notes: {e}", exc_info=True)
        await db.rollback()
        raise

async def create_resources_async(
    goal: Goal,
    objective: Objective,
    db: AsyncSession,
    onboarding_prompt: str | None = None,
    questions_answers: list[tuple[str, str]] | None = None
) -> None:
    """Search for and save resources using Gemini"""
    try:
        # Build student context list for resource search
        student_context_list = None
        if onboarding_prompt or questions_answers:
            student_context_list = []
            if onboarding_prompt:
                student_context_list.append(f"Initial goal: {onboarding_prompt}")
            if questions_answers:
                qa_text = "; ".join([f"{q}: {a}" for q, a in questions_answers])
                student_context_list.append(f"Onboarding Q&A: {qa_text}")
        
        # Search for resources
        resources = search_resources(
            goal_id=goal.id,
            goal_name=goal.name,
            goal_description=goal.description,
            objective_id=objective.id,
            objective_name=objective.name,
            objective_description=objective.description,
            student_context=student_context_list
        )
        
        # Save resources to database
        resource_repo = ResourceRepository(db)
        for resource in resources:
            await resource_repo.create(resource)
        
        await db.commit()
    except Exception as e:
        logger.error(f"Error creating resources: {e}", exc_info=True)
        await db.rollback()
        raise

async def create_student_context_async(
    student: Student,
    goal: Goal,
    objective: Objective,
    db: AsyncSession,
    onboarding_prompt: str | None = None,
    questions_answers: list[tuple[str, str]] | None = None
) -> None:
    """Create initial student context using Gemini"""
    try:
        gemini_context = gemini_generate_student_context(
            goal_name=goal.name,
            goal_description=goal.description,
            objective_name=objective.name,
            objective_description=objective.description,
            onboarding_prompt=onboarding_prompt,
            questions_answers=questions_answers
        )
        
        # Generate embeddings
        state_embedding = get_gemini_embeddings(gemini_context.state)
        metacognition_embedding = get_gemini_embeddings(gemini_context.metacognition)
        
        # Create student context
        student_context = StudentContext(
            student_id=student.id,
            goal_id=goal.id,
            objective_id=objective.id,
            state=gemini_context.state,
            state_embedding=state_embedding,
            metacognition=gemini_context.metacognition,
            metacognition_embedding=metacognition_embedding
        )
        
        context_repo = StudentContextRepository(db)
        await context_repo.create(student_context)
        await db.commit()
    except Exception as e:
        logger.error(f"Error creating student context: {e}", exc_info=True)
        await db.rollback()
        raise