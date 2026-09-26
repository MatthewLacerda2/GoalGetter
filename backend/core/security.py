import logging
import secrets
from datetime import timedelta

import httpx
import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from google.auth.exceptions import TransportError
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


GOOGLE_USERINFO_URL = "https://www.googleapis.com/oauth2/v2/userinfo"


def _invalid_google_token() -> HTTPException:
    return HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid Google token")


def _google_unreachable() -> HTTPException:
    """Google did not answer: nothing is known about the token, so not a 401 (#186)."""
    return HTTPException(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Could not reach Google"
    )


async def verify_google_token(token: str) -> dict:
    """
    Verify a Google OAuth2 token (ID token or access token) and return the user information.

    A token Google rejects answers 401; Google out of reach answers 503. The
    client is told which, never the exception's text: that goes to the log.
    """
    try:
        idinfo = id_token.verify_oauth2_token(token, requests.Request(), GOOGLE_CLIENT_ID)
        return {
            "sub": idinfo["sub"],  # Google's unique user ID
            "email": idinfo["email"],
            "name": idinfo.get("name"),
            "picture": idinfo.get("picture"),
            "email_verified": idinfo.get("email_verified", False),
        }
    except TransportError as err:
        logger.error("Could not fetch Google's certificates: %s", err)
        raise _google_unreachable() from err
    except Exception as err:
        # Not an ID token: an access token ("ya29.…") is verified by asking
        # Google who it belongs to.
        if not (token.startswith("ya29.") or "Wrong number of segments" in str(err)):
            logger.info("Google ID token rejected: %s", err)
            raise _invalid_google_token() from err
    return await _verify_google_access_token(token)


async def _verify_google_access_token(token: str) -> dict:
    # The token rides in the header, not the query string, so the URL that
    # httpx logs does not carry it.
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                GOOGLE_USERINFO_URL, headers={"Authorization": f"Bearer {token}"}
            )
    except httpx.RequestError as err:
        logger.error("Could not reach Google's userinfo: %s", err)
        raise _google_unreachable() from err
    try:
        response.raise_for_status()
        userinfo = response.json()
        return {
            "sub": userinfo["id"],  # Google's unique user ID
            "email": userinfo["email"],
            "name": userinfo.get("name"),
            "picture": userinfo.get("picture"),
            "email_verified": userinfo.get("verified_email", False),
        }
    except Exception as err:
        logger.info("Google access token rejected: %s", err)
        raise _invalid_google_token() from err


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
    """The student the token names. Only a problem with the token answers 401,
    because the app reads 401 as "your session ended" and signs the student out
    (#186). Anything else — the database down, a bug in the lookup — is left to
    raise and answers 500, which the app does not read as a sign-out."""
    payload = verify_token(credentials.credentials)
    google_id = payload.get("sub")
    if not google_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token payload"
        )

    student = await StudentRepository(db).get_by_google_id(google_id)
    if student is None:
        # A valid token for a student who no longer exists (the account was
        # deleted): the session really is over, so 401 — signing him out is
        # the right thing — but said, not folded into "invalid token".
        logger.warning("Token for a student who no longer exists")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Student no longer exists"
        )
    return student


async def verify_google_token_header(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """
    Verify a Google OAuth2 token from the Authorization header.
    Returns the user info from Google without requiring the user to exist in the database.
    """
    google_token = credentials.credentials.strip()
    if not google_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Google token is empty"
        )
    return await verify_google_token(google_token)
