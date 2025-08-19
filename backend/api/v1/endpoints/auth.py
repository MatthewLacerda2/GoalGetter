from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status, Response
from backend.core.security import create_access_token, verify_google_token, get_current_user
from backend.core.database import get_db
from backend.schemas.student import OAuth2Request, TokenResponse
from backend.models.student import Student
from backend.models.goal import Goal
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError
from sqlalchemy import select
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
                detail="User already exists"
            )
        
        user = Student(
            email=user_info["email"],
            google_id=user_info["sub"],
            name=user_info.get("name"),
            latest_report="",
        )
        
        goal = Goal(    #TODO: Create the actual goal
            name="Default Goal",
            description="Your initial learning goal"
        )        
        db.add(goal)
        await db.flush()
        
        user.goal_id = goal.id
        user.goal_name = goal.name  # Set the goal_name on the model
        
        access_token = create_access_token(
            data={"sub": str(user.id)},
        )
        
        db.add(user)
        await db.commit()
        await db.refresh(user)
        
        token_response = TokenResponse(
            access_token=access_token,
            student=user
        )
        # Remove this line since goal_name is now on the model
        # token_response.student.goal_name = goal.name
        
        return token_response
        
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
        
        goal_id = user.goal_id
        stmt = select(Goal).where(Goal.id == goal_id)
        result = await db.execute(stmt)
        goal = result.scalar_one_or_none()
        
        if not goal:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Goal not found"
            )        
        
        user.goal = goal        
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
