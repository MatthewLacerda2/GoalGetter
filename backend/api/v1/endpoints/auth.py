from fastapi import APIRouter, Depends, HTTPException, status, Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError
from datetime import datetime
import logging
from backend.core.security import create_access_token, verify_google_token, get_current_user
from backend.core.database import get_db
from backend.schemas.student import OAuth2Request, TokenResponse
from backend.models.student import Student
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
    try:
        user_info = verify_google_token(oauth_data.access_token)
        
        student_repo = StudentRepository(db)
        user = await student_repo.get_by_google_id(user_info["sub"])
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        user.last_login = datetime.now()
        updated_user = await student_repo.update(user)
        await db.commit()
        
        access_token = create_access_token(
            data={"sub": updated_user.google_id},  # Use google_id instead of str(updated_user.id)
        )
        
        return TokenResponse(
            access_token=access_token,
            student=updated_user
        )
        
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Internal server error"
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
        success = await student_repo.delete(current_user.id)
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        await db.commit()
        return Response(status_code=status.HTTP_204_NO_CONTENT)
        
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error deleting account"
        )
