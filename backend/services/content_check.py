import logging
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession
from backend.models.multiple_choice_question import MultipleChoiceQuestion
from backend.models.objective_note import ObjectiveNote
from backend.models.resource import Resource
from backend.models.student_context import StudentContext

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
        mcq_stmt = select(func.count(MultipleChoiceQuestion.id)).where(
            MultipleChoiceQuestion.objective_id == objective_id
        )
        mcq_result = await db.execute(mcq_stmt)
        mcq_count = mcq_result.scalar() or 0
        
        # Check objective notes count
        notes_stmt = select(func.count(ObjectiveNote.id)).where(
            ObjectiveNote.objective_id == objective_id
        )
        notes_result = await db.execute(notes_stmt)
        notes_count = notes_result.scalar() or 0
        
        # Check resources count for goal
        resources_stmt = select(func.count(Resource.id)).where(
            Resource.goal_id == goal_id
        )
        resources_result = await db.execute(resources_stmt)
        resources_count = resources_result.scalar() or 0
        
        # Check student context count for objective and student
        context_stmt = select(func.count(StudentContext.id)).where(
            and_(
                StudentContext.objective_id == objective_id,
                StudentContext.student_id == student_id
            )
        )
        context_result = await db.execute(context_stmt)
        context_count = context_result.scalar() or 0
        
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
