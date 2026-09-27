from typing import Annotated

from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from backend.api.v1.student_dependencies import get_current_user, remember_language
from backend.core import clock
from backend.core.config import settings
from backend.core.database import get_db
from backend.core.errors.api_error import ApiError
from backend.core.errors.codes import ErrorCode
from backend.core.language import Language, requested_language
from backend.core.security import (
    create_access_token,
    verify_google_token,
    verify_google_token_header,
)
from backend.models.student import Student
from backend.repositories.student_repository import StudentRepository
from backend.schemas.student import (
    DevLoginRequest,
    OAuth2Request,
    StudentResponse,
    TokenRefreshRequest,
    TokenRefreshResponse,
    TokenResponse,
)
from backend.services.auth import token_rotation
from backend.services.fictitious.identity import fictitious_identity

router = APIRouter()


async def _token_response(db: AsyncSession, student: Student) -> TokenResponse:
    """Issue a fresh access + refresh token pair for `student` and commit.
    Shared by every route that answers `token_response`."""
    refresh_token_str = await token_rotation.issue(db, student.id)
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
    user_info: Annotated[dict, Depends(verify_google_token_header)],
    db: Annotated[AsyncSession, Depends(get_db)],
    language: Annotated[Language | None, Depends(requested_language)],
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
    remember_language(user, language)
    await student_repo.update(user)
    return await _token_response(db, user)


@router.post("/login", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def login(oauth_data: OAuth2Request, db: Annotated[AsyncSession, Depends(get_db)]):
    """
    Login using Google OAuth2 token.
    """
    user_info = await verify_google_token(oauth_data.access_token)
    student_repo = StudentRepository(db)
    user = await student_repo.get_by_google_id(user_info["sub"])
    if not user:
        raise ApiError(ErrorCode.STUDENT_NOT_FOUND)
    user.last_login = clock.now()
    await student_repo.update(user)
    return await _token_response(db, user)


def require_dev_login():
    """404 unless DEV_LOGIN is on, so production answers as if the route did not
    exist - the same code and body as an unknown route. Read per request (not at
    import) so tests can flip the setting."""
    if not settings.DEV_LOGIN:
        raise ApiError(ErrorCode.ROUTE_NOT_FOUND)


@router.post(
    "/dev-login",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_dev_login)],
    include_in_schema=settings.DEV_LOGIN,
)
async def dev_login(
    payload: DevLoginRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    language: Annotated[Language | None, Depends(requested_language)],
):
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
    remember_language(student, language)
    await student_repo.update(student)
    return await _token_response(db, student)


@router.post("/refresh", response_model=TokenRefreshResponse)
async def refresh_tokens(
    payload: TokenRefreshRequest, db: Annotated[AsyncSession, Depends(get_db)]
):
    """
    Refresh access and refresh tokens. Implements Refresh Token Rotation (RTR):
    the token presented is revoked and replaced, and presenting one that was
    already replaced revokes its successors (`services/auth/token_rotation.py`).
    """
    rotated = await token_rotation.rotate(db, payload.refresh_token)
    # Committed before a refusal too: a replayed token revokes its successors.
    await db.commit()
    if rotated is None:
        raise ApiError(ErrorCode.INVALID_REFRESH_TOKEN)
    student_id, new_refresh_token = rotated
    student = await StudentRepository(db).get_by_id(student_id)
    return TokenRefreshResponse(
        access_token=create_access_token(data={"sub": student.google_id}),
        refresh_token=new_refresh_token,
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(payload: TokenRefreshRequest, db: Annotated[AsyncSession, Depends(get_db)]):
    """
    Revoke a refresh token (logout).
    """
    await token_rotation.revoke(db, payload.refresh_token)
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.delete("/account", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[Student, Depends(get_current_user)],
):
    """Delete the signed-in student. Anything that fails on the way is a 500
    `internal_error` (core/errors/handlers.py), and the session closes without
    committing, so nothing is half deleted."""
    if not await StudentRepository(db).delete(current_user.id):
        raise ApiError(ErrorCode.STUDENT_NOT_FOUND)
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
