import logging
import secrets
from datetime import timedelta

import httpx
import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from google.auth.transport import requests
from google.oauth2 import id_token
from sqlalchemy.ext.asyncio import AsyncSession

from backend.core import clock
from backend.core.config import settings
from backend.core.database import get_db
from backend.core.language import Language, requested_language
from backend.models.student import Student
from backend.repositories.student_repository import StudentRepository
from backend.utils.envs import GOOGLE_CLIENT_ID, JWT_AUDIENCE, JWT_ISSUER

logger = logging.getLogger(__name__)


def create_access_token(data: dict, expires_delta: timedelta = None) -> str:
    """
    Create a JWT access token with the given data and expiration time.
    """
    to_encode = data.copy()
    expire = clock.now() + (expires_delta or timedelta(minutes=30))
    to_encode.update(
        {
            "iss": JWT_ISSUER,  # Add issuer claim
            "aud": JWT_AUDIENCE,  # Add audience claim
            "exp": expire,
        }
    )
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm="HS256")
    return encoded_jwt


def generate_refresh_token_string() -> str:
    """Generates a secure random refresh token string"""
    return secrets.token_urlsafe(64)


async def verify_google_token(token: str) -> dict:
    """
    Verify a Google OAuth2 token (ID token or access token) and return the user information.

    Args:
        token: The Google OAuth2 ID token or access token

    Returns:
        dict: User information from Google

    Raises:
        HTTPException: If the token is invalid or verification fails
    """
    # First, try to verify as ID token (JWT)
    try:
        idinfo = id_token.verify_oauth2_token(token, requests.Request(), GOOGLE_CLIENT_ID)
        return {
            "sub": idinfo["sub"],  # Google's unique user ID
            "email": idinfo["email"],
            "name": idinfo.get("name"),
            "picture": idinfo.get("picture"),
            "email_verified": idinfo.get("email_verified", False),
        }
    except (ValueError, Exception) as e:
        # If ID token verification fails, try verifying as access token
        # Access tokens start with "ya29." or similar prefixes
        if token.startswith("ya29.") or "Wrong number of segments" in str(e):
            try:
                # Verify access token asynchronously by calling Google's userinfo endpoint
                userinfo_url = f"https://www.googleapis.com/oauth2/v2/userinfo?access_token={token}"
                async with httpx.AsyncClient() as client:
                    response = await client.get(userinfo_url)
                    response.raise_for_status()
                    userinfo = response.json()

                return {
                    "sub": userinfo["id"],  # Google's unique user ID
                    "email": userinfo["email"],
                    "name": userinfo.get("name"),
                    "picture": userinfo.get("picture"),
                    "email_verified": userinfo.get("verified_email", False),
                }
            except Exception as access_token_error:
                logger.error(f"Failed to verify access token: {access_token_error}")
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail=f"Invalid Google token: {access_token_error}",
                ) from access_token_error
        else:
            # Re-raise the original error for ID token verification failures
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid Google token"
            ) from e


def verify_token(token: str) -> dict:
    """
    Verify a JWT token and return the payload.

    Args:
        token: The JWT token to verify

    Returns:
        dict: The token payload

    Raises:
        HTTPException: If the token is invalid
    """
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=["HS256"],
            issuer=JWT_ISSUER,
            audience=JWT_AUDIENCE,
        )
        return payload
    except jwt.PyJWTError as err:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token"
        ) from err


security = HTTPBearer()


def remember_language(student: Student, language: Language | None) -> bool:
    """Mirror the language the app sent onto the student; True if it changed.
    Nothing sent leaves what is stored alone."""
    if language is None or student.language == language:
        return False
    student.language = language
    return True


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db),
    language: Language | None = Depends(requested_language),
) -> Student:
    """
    Get the current authenticated user from the JWT token, and keep his
    language up to date with the one the app sent (#172, `core/language.py`).
    """
    user = await _user_from_token(credentials, db)
    if remember_language(user, language):
        await StudentRepository(db).update(user)
        await db.commit()
    return user


async def _user_from_token(credentials: HTTPAuthorizationCredentials, db: AsyncSession) -> Student:
    try:
        payload = verify_token(credentials.credentials)

        # Get user_id from token payload
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token payload"
            )

        student_repo = StudentRepository(db)
        user = await student_repo.get_by_google_id(user_id)

        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

        return user

    except jwt.PyJWTError as err:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token"
        ) from err
    except Exception as err:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Could not validate credentials"
        ) from err


async def verify_google_token_header(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """
    Verify a Google OAuth2 token from the Authorization header.
    Returns the user info from Google without requiring the user to exist in the database.
    """
    try:
        # Extract the token from "Bearer <token>"
        google_token = credentials.credentials
        if not google_token or not google_token.strip():
            logger.error("Empty or whitespace-only Google token received")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail="Google token is empty"
            )
        logger.info(f"Verifying Google token (length: {len(google_token.strip())})")
        return await verify_google_token(google_token.strip())
    except HTTPException:
        # Re-raise HTTPException directly to preserve the original error message
        raise
    except Exception as e:
        logger.error(f"Error verifying Google token: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Invalid Google token: {str(e)}"
        ) from e
