import logging
from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from backend.core import clock
from backend.core.config import settings
from backend.core.database import get_db
from backend.core.security import (
    create_access_token,
    generate_refresh_token_string,
    get_current_user,
    verify_google_token,
    verify_google_token_header,
)
from backend.models.refresh_token import RefreshToken
from backend.models.student import Student
from backend.repositories.refresh_token_repository import RefreshTokenRepository
from backend.repositories.student_repository import StudentRepository
from backend.schemas.student import (
    DevLoginRequest,
    OAuth2Request,
    StudentResponse,
    TokenRefreshRequest,
    TokenRefreshResponse,
    TokenResponse,
)
from backend.services.fictitious.identity import fictitious_identity

logger = logging.getLogger(__name__)

router = APIRouter()


async def _token_response(db: AsyncSession, student: Student) -> TokenResponse:
    """Issue a fresh access + refresh token pair for `student` and commit.
    Shared by every route that answers `token_response`."""
    refresh_token_str = generate_refresh_token_string()
    await RefreshTokenRepository(db).create(
        RefreshToken(
            student_id=student.id,
            token=refresh_token_str,
            expires_at=clock.now() + timedelta(days=30),
        )
    )
    await db.commit()
    await db.refresh(student)
    return TokenResponse(
        access_token=create_access_token(data={"sub": student.google_id}),
        refresh_token=refresh_token_str,
        student=StudentResponse(
            id=str(student.id), google_id=student.google_id, email=student.email, name=student.name
        ),
    )


@router.post("/signup", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def signup(
    user_info: dict = Depends(verify_google_token_header), db: AsyncSession = Depends(get_db)
):
    """
    Sign up or sign in using Google OAuth2 token.
    Creates a new account if the user doesn't exist, or returns existing account info.
    """
    student_repo = StudentRepository(db)
    user = await student_repo.get_by_google_id(user_info["sub"])
    if not user:
        user = await student_repo.create(
            Student(
                email=user_info["email"], google_id=user_info["sub"], name=user_info.get("name", "")
            )
        )
    else:
        user.last_login = clock.now()
        await student_repo.update(user)
    return await _token_response(db, user)


@router.post("/login", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def login(oauth_data: OAuth2Request, db: AsyncSession = Depends(get_db)):
    """
    Login using Google OAuth2 token.
    """
    user_info = await verify_google_token(oauth_data.access_token)
    student_repo = StudentRepository(db)
    user = await student_repo.get_by_google_id(user_info["sub"])
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    user.last_login = clock.now()
    await student_repo.update(user)
    return await _token_response(db, user)


def require_dev_login():
    """404 unless DEV_LOGIN is on, so production answers as if the route did not
    exist. Read per request (not at import) so tests can flip the setting."""
    if not settings.DEV_LOGIN:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not Found")


@router.post(
    "/dev-login",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_dev_login)],
    include_in_schema=settings.DEV_LOGIN,
)
async def dev_login(payload: DevLoginRequest, db: AsyncSession = Depends(get_db)):
    """
    Dev only: sign in as a fictitious student, no Google involved. Creates or
    reuses the student named `Fictitious <name>` (services/fictitious/identity.py).
    """
    identity = fictitious_identity(payload.name)
    student_repo = StudentRepository(db)
    student = await student_repo.get_by_google_id(identity.google_id)
    if not student:
        student = await student_repo.create(
            Student(email=identity.email, google_id=identity.google_id, name=identity.name)
        )
    else:
        student.last_login = clock.now()
        await student_repo.update(student)
    return await _token_response(db, student)


@router.post("/refresh", response_model=TokenRefreshResponse)
async def refresh_tokens(payload: TokenRefreshRequest, db: AsyncSession = Depends(get_db)):
    """
    Refresh access and refresh tokens. Implements Refresh Token Rotation (RTR).
    """
    repo = RefreshTokenRepository(db)
    token_obj = await repo.get_by_token(payload.refresh_token)

    if not token_obj or token_obj.revoked or clock.as_utc(token_obj.expires_at) < clock.now():
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired refresh token"
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
        student_id=student.id, token=new_refresh_str, expires_at=clock.now() + timedelta(days=30)
    )
    await repo.create(new_refresh_obj)
    await db.commit()

    return TokenRefreshResponse(
        access_token=create_access_token(data={"sub": student.google_id}),
        refresh_token=new_refresh_str,
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(payload: TokenRefreshRequest, db: AsyncSession = Depends(get_db)):
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
    db: AsyncSession = Depends(get_db), current_user: Student = Depends(get_current_user)
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
            detail=f"Error deleting account: {str(e)}",
        ) from e
