import logging
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import APIRouter, Depends, HTTPException, status, Response
from backend.core.database import get_db
from backend.core.security import create_access_token, verify_google_token, get_current_user
from backend.models.student import Student
from backend.schemas.student import OAuth2Request, TokenResponse
from backend.repositories.student_repository import StudentRepository

logger = logging.getLogger(__name__)

router = APIRouter()

@router.post("/login", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def login(
    oauth_data: OAuth2Request,
    db: AsyncSession = Depends(get_db)
):
    """
    Login using Google OAuth2 token.
    """
    user_info = verify_google_token(oauth_data.access_token)    
    student_repo = StudentRepository(db)
    user = await student_repo.get_by_google_id(user_info["sub"])
    
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    
    user.last_login = datetime.now()
    updated_user = await student_repo.update(user)
    
    access_token = create_access_token(
        data={"sub": updated_user.google_id},  # Use google_id instead of str(updated_user.id)
    )
    
    await db.commit()
    
    return TokenResponse(
        access_token=access_token,
        student=updated_user
    )

@router.delete("/account", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """
    Delete user account and all associated data
    """
    try:
        student_repo = StudentRepository(db)
        
        # Clear foreign key references before deletion to avoid constraint issues
        # Since each goal belongs to only one student, only this student could reference their goals
        current_user.goal_id = None
        current_user.goal_name = None
        current_user.current_objective_id = None
        current_user.current_objective_name = None
        await student_repo.update(current_user)
        await db.flush()
        
        success = await student_repo.delete(current_user.id)
        
        if not success:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        
        await db.commit()
        return Response(status_code=status.HTTP_204_NO_CONTENT)
        
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        logger.error(f"Error deleting account: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error deleting account: {str(e)}"
        )
