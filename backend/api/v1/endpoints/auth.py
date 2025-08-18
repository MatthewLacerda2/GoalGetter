from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status, Response
from backend.core.security import create_access_token, verify_google_token, get_current_user
from backend.core.database import get_db
from backend.schemas.student import OAuth2Request, TokenResponse
from backend.models.student import Student
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError
from sqlalchemy import select
from backend.core.errors import USER_ALREADY_EXISTS
from backend.core.logging_middleware import LoggingMiddleware
import logging

logger = logging.getLogger(__name__)

router = APIRouter()

@router.post("/signup", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def signup(
    oauth_data: OAuth2Request,
    db: AsyncSession = Depends(get_db)
):
    """
    Sign up a new user using Google OAuth2 token.
    """
    try:
        user_info = verify_google_token(oauth_data.access_token)
        
        stmt = select(Student).where(Student.google_id == user_info["sub"])
        result = await db.execute(stmt)
        existing_user = result.scalar_one_or_none()
        
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=USER_ALREADY_EXISTS
            )
        
        user = Student(
            email=user_info["email"],
            google_id=user_info["sub"],
            name=user_info.get("name"),
            latest_report="",
        )
        
        logger.info(f"\nUSER INFO ZXC: {user_info}")
        
        access_token = create_access_token(
            data={"sub": str(user.id)},
        )
        
        logger.info(f"\nACCESS TOKEN: {access_token}")
        
        db.add(user)
        await db.commit()
        await db.refresh(user)
        
        logger.info(f"\nWRITTEN TO DB: {user}")
        
        return TokenResponse(
            access_token=access_token,
            student=user
        )
        
    except IntegrityError as e:
        print(f"\nINTEGRITY ERROR IN SIGNUP: {type(e).__name__}: {str(e)}")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="User already exists"
        )
    except HTTPException:
        raise
    except Exception as e:
        print(f"\nEXCEPTION CAUGHT IN SIGNUP: {type(e).__name__}: {str(e)}")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Google token at signup {e}"
        )

@router.post("/login", response_model=TokenResponse)
async def login(
    oauth_data: OAuth2Request,
    db: AsyncSession = Depends(get_db)
):
    """
    Login using Google OAuth2 token.
    """
    try:
        user_info = verify_google_token(oauth_data.access_token)
        
        stmt = select(Student).where(Student.google_id == user_info["sub"])
        result = await db.execute(stmt)
        user = result.scalar_one_or_none()
        
        user.last_login = datetime.now()
        await db.commit()
        await db.refresh(user)
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        access_token = create_access_token(
            data={"sub": str(user.id)},
        )
        
        return TokenResponse(
            access_token=access_token,
            student=user
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Internal server error at login: {str(e)}"
        )

@router.delete("/account", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """
    Delete user account and all associated data (alert prompts)
    """
    try:
        await db.delete(current_user)
        await db.commit()
        
        return Response(status_code=status.HTTP_204_NO_CONTENT)
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error deleting account"
        )
