import logging
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import delete
from fastapi import APIRouter, Depends, HTTPException, status, Response
from backend.core.database import get_db
from backend.core.security import create_access_token, verify_google_token, get_current_user, verify_google_token_header
from backend.models.student import Student
from backend.schemas.student import OAuth2Request, TokenResponse, StudentResponse
from backend.repositories.student_repository import StudentRepository

logger = logging.getLogger(__name__)

router = APIRouter()

@router.post("/signup", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def signup(
    user_info: dict = Depends(verify_google_token_header),
    db: AsyncSession = Depends(get_db)
):
    """
    Sign up or sign in using Google OAuth2 token.
    Creates a new account if the user doesn't exist, or returns existing account info.
    """
    student_repo = StudentRepository(db)
    user = await student_repo.get_by_google_id(user_info["sub"])
    
    if not user:
        # Create new student account
        user = Student(
            email=user_info["email"],
            google_id=user_info["sub"],
            name=user_info.get("name", ""),
        )
        user = await student_repo.create(user)
        await db.commit()
        await db.refresh(user)
    else:
        # Update last_login for existing user
        user.last_login = datetime.now()
        await student_repo.update(user)
        await db.commit()
        await db.refresh(user)
    
    access_token = create_access_token(
        data={"sub": user.google_id},
    )
    
    student_response = StudentResponse(
        id=str(user.id),
        google_id=user.google_id,
        email=user.email,
        name=user.name
    )
    
    return TokenResponse(
        access_token=access_token,
        student=student_response
    )

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
    
    student_response = StudentResponse(
        id=str(updated_user.id),
        google_id=updated_user.google_id,
        email=updated_user.email,
        name=updated_user.name
    )
    
    return TokenResponse(
        access_token=access_token,
        student=student_response
    )

@router.delete("/account", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """
    Delete user account and all associated data.
    Database CASCADE will automatically delete related goals and their objectives.
    Use bulk delete to bypass ORM relationship handling which causes constraint violations.
    """
    try:
        # Use SQLAlchemy's delete statement directly to bypass ORM relationship tracking
        # This allows the database CASCADE to handle related records without ORM interference
        stmt = delete(Student).where(Student.id == current_user.id)
        result = await db.execute(stmt)
        
        if result.rowcount == 0:
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
