import logging
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import APIRouter, Depends, HTTPException, status, Response
from backend.core.database import get_db
from backend.core.security import (
    create_access_token,
    verify_google_token,
    get_current_user,
    verify_google_token_header,
    generate_refresh_token_string
)
from backend.models.student import Student
from backend.models.refresh_token import RefreshToken
from backend.schemas.student import (
    OAuth2Request,
    TokenResponse,
    StudentResponse,
    TokenRefreshRequest,
    TokenRefreshResponse
)
from backend.repositories.student_repository import StudentRepository
from backend.repositories.refresh_token_repository import RefreshTokenRepository

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
    refresh_token_repo = RefreshTokenRepository(db)
    user = await student_repo.get_by_google_id(user_info["sub"])
    
    if not user:
        # Create new student account
        user = Student(
            email=user_info["email"],
            google_id=user_info["sub"],
            name=user_info.get("name", "")
        )
        user = await student_repo.create(user)
        await db.flush()
    else:
        # Update last_login for existing user
        user.last_login = datetime.now()
        await student_repo.update(user)
        await db.flush()
        
    # Generate tokens
    access_token = create_access_token(data={"sub": user.google_id})
    refresh_token_str = generate_refresh_token_string()
    
    refresh_token_obj = RefreshToken(
        student_id=user.id, token=refresh_token_str, expires_at=datetime.now() + timedelta(days=30)
    )
    await refresh_token_repo.create(refresh_token_obj)
    await db.commit()
    await db.refresh(user)
    
    student_response = StudentResponse(
        id=str(user.id), google_id=user.google_id, email=user.email, name=user.name
    )
    
    return TokenResponse(
        access_token=access_token, refresh_token=refresh_token_str, student=student_response
    )

@router.post("/login", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def login(
    oauth_data: OAuth2Request,
    db: AsyncSession = Depends(get_db)
):
    """
    Login using Google OAuth2 token.
    """
    user_info = await verify_google_token(oauth_data.access_token)    
    student_repo = StudentRepository(db)
    refresh_token_repo = RefreshTokenRepository(db)
    user = await student_repo.get_by_google_id(user_info["sub"])
    
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    
    user.last_login = datetime.now()
    updated_user = await student_repo.update(user)
    await db.flush()
    
    # Generate tokens
    access_token = create_access_token(data={"sub": updated_user.google_id})
    refresh_token_str = generate_refresh_token_string()
    
    refresh_token_obj = RefreshToken(
        student_id=updated_user.id,
        token=refresh_token_str,
        expires_at=datetime.now() + timedelta(days=30)
    )
    await refresh_token_repo.create(refresh_token_obj)
    await db.commit()
    
    student_response = StudentResponse(
        id=str(updated_user.id),
        google_id=updated_user.google_id,
        email=updated_user.email,
        name=updated_user.name
    )
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token_str,
        student=student_response
    )

@router.post("/refresh", response_model=TokenRefreshResponse)
async def refresh_tokens(
    payload: TokenRefreshRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Refresh access and refresh tokens. Implements Refresh Token Rotation (RTR).
    """
    repo = RefreshTokenRepository(db)
    token_obj = await repo.get_by_token(payload.refresh_token)
    
    if not token_obj or token_obj.revoked or token_obj.expires_at < datetime.now():
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token"
        )
        
    # Revoke old refresh token (Rotation)
    token_obj.revoked = True
    await repo.update(token_obj)
    await db.flush()
    
    # Generate new pair
    student_repo = StudentRepository(db)
    student = await student_repo.get_by_id(token_obj.student_id)
    
    new_refresh_str = generate_refresh_token_string()
    new_refresh_obj = RefreshToken(
        student_id=student.id,
        token=new_refresh_str,
        expires_at=datetime.now() + timedelta(days=30)
    )
    await repo.create(new_refresh_obj)
    await db.commit()
    
    return TokenRefreshResponse(
        access_token=create_access_token(data={"sub": student.google_id}),
        refresh_token=new_refresh_str
    )

@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(
    payload: TokenRefreshRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Revoke a refresh token (logout).
    """
    repo = RefreshTokenRepository(db)
    token_obj = await repo.get_by_token(payload.refresh_token)
    if token_obj:
        token_obj.revoked = True
        await repo.update(token_obj)
        await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)

@router.delete("/account", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    try:
        student_repo = StudentRepository(db)
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
