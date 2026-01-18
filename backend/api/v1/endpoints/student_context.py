import logging
from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.ext.asyncio import AsyncSession
from backend.core.database import get_db
from backend.core.security import get_current_user
from backend.models.student import Student
from backend.models.student_context import StudentContext
from backend.schemas.student_context import StudentContextResponse, StudentContextItem, CreateStudentContextRequest
from backend.repositories.student_context_repository import StudentContextRepository

logger = logging.getLogger(__name__)

router = APIRouter()

@router.get("", response_model=StudentContextResponse, status_code=status.HTTP_200_OK)
async def get_student_contexts(
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """Get student contexts for the current user's objective"""
    
    if not current_user.current_objective_id:
        return StudentContextResponse(contexts=[])
    
    context_repo = StudentContextRepository(db)
    contexts = await context_repo.get_by_student_and_objective(
        student_id=str(current_user.id),
        objective_id=str(current_user.current_objective_id),
        limit=50
    )
    
    # Extract attributes before leaving async context
    context_items = [
        StudentContextItem(
            id=str(context.id),
            created_at=context.created_at,
            state=context.state,
            metacognition=context.metacognition
        )
        for context in contexts
    ]
    
    return StudentContextResponse(contexts=context_items)

@router.post("", response_model=StudentContextItem, status_code=status.HTTP_201_CREATED)
async def create_student_context(
    request: CreateStudentContextRequest,
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """Create a new student context"""
    
    if not current_user.goal_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Student must have an active goal to create context"
        )
    
    context_repo = StudentContextRepository(db)
    
    student_context = StudentContext(
        student_id=current_user.id,
        goal_id=current_user.goal_id,
        objective_id=current_user.current_objective_id,
        source="student",
        state=request.context,
        metacognition="",
        state_embedding=None,
        metacognition_embedding=None,
        ai_model="non-artificial"
    )
    
    created_context = await context_repo.create(student_context)
    await db.commit()
    await db.refresh(created_context)
    
    # Extract attributes before leaving async context
    context_data = {
        "id": str(created_context.id),
        "created_at": created_context.created_at,
        "state": created_context.state,
        "metacognition": created_context.metacognition
    }
    
    return StudentContextItem(**context_data)

@router.delete("/{context_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_student_context(
    context_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """Delete a student context"""
    
    context_repo = StudentContextRepository(db)
    context = await context_repo.get_by_id(context_id)
    
    if not context:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student context not found"
        )
    
    if context.student_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Student context does not belong to the current student"
        )
    
    await context_repo.delete(context_id)
    await db.commit()
    
    return Response(status_code=status.HTTP_204_NO_CONTENT)
