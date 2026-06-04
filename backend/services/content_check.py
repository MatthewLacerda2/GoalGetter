import logging
from sqlalchemy.ext.asyncio import AsyncSession
from backend.repositories.multiple_choice_question_repository import MultipleChoiceQuestionRepository
from backend.repositories.objective_note_repository import ObjectiveNoteRepository
from backend.repositories.resource_repository import ResourceRepository
from backend.repositories.student_context_repository import StudentContextRepository

logger = logging.getLogger(__name__)


async def objective_missing_content(
    objective_id: str,
    goal_id: str,
    student_id: str,
    db: AsyncSession
) -> bool:
    """
    Check if an objective is missing any content.
    
    Returns True if ANY of the following are missing:
    - Multiple choice questions (count == 0)
    - Objective notes (count == 0)
    - Resources for goal (count == 0)
    - Student context for objective (count == 0)
    
    Args:
        objective_id: The objective ID to check
        goal_id: The goal ID (for resource checking)
        student_id: The student ID (for student context checking)
        db: Database session
        
    Returns:
        True if any content is missing, False if all content exists
    """
    try:
        # Check multiple choice questions count
        mcq_repo = MultipleChoiceQuestionRepository(db)
        mcq_count = await mcq_repo.count_by_objective_id(objective_id)
        
        # Check objective notes count
        notes_repo = ObjectiveNoteRepository(db)
        notes_count = await notes_repo.count_by_objective_id(objective_id)
        
        # Check resources count for goal
        resources_repo = ResourceRepository(db)
        resources_count = await resources_repo.count_by_goal_id(goal_id)
        
        # Check student context count for objective and student
        context_repo = StudentContextRepository(db)
        context_count = await context_repo.count_by_objective_and_student(objective_id, student_id)
        
        # Return True if ANY content is missing
        missing = (mcq_count == 0 or notes_count == 0 or resources_count == 0 or context_count == 0)
        
        if missing:
            logger.debug(
                f"Objective {objective_id} missing content: "
                f"MCQs={mcq_count}, Notes={notes_count}, Resources={resources_count}, Context={context_count}"
            )
        
        return missing
        
    except Exception as e:
        logger.error(f"Error checking content for objective {objective_id}: {e}", exc_info=True)
        # On error, assume content is missing to be safe (will trigger content creation)
        return True

