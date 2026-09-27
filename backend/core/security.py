import asyncio
import logging
from datetime import timedelta

import httpx
import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from google.auth.exceptions import TransportError
from google.oauth2 import id_token

from backend.core import clock
from backend.core.config import settings
from backend.core.google_certs import GOOGLE_CERTS

logger = logging.getLogger(__name__)

# Who signs the app's own tokens and who they are for. Constants, not settings:
# a token names them, so changing either signs every student out.
JWT_ISSUER = "https://goalsgetter.org/api/v1"
JWT_AUDIENCE = "https://goalsgetter.org/api/v1"


def create_access_token(data: dict, expires_delta: timedelta | None = None) -> str:
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


GOOGLE_USERINFO_URL = "https://www.googleapis.com/oauth2/v2/userinfo"


def _invalid_google_token() -> HTTPException:
    return HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid Google token")


def _google_unreachable() -> HTTPException:
    """Google did not answer: nothing is known about the token, so not a 401 (#186)."""
    return HTTPException(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Could not reach Google"
    )


def _verify_id_token(token: str) -> dict:
    """google-auth fetches Google's certificates with `requests`, synchronously:
    called on the event loop, one slow fetch stalls every request in flight, so
    `verify_google_token` runs this in a worker thread (#210). The certificates
    are kept for as long as Google says they stay valid, not refetched per call (#258)."""
    return id_token.verify_oauth2_token(token, GOOGLE_CERTS, settings.GOOGLE_CLIENT_ID)


async def verify_google_token(token: str) -> dict:
    """
    Verify a Google OAuth2 token (ID token or access token) and return the user information.

    A token Google rejects answers 401; Google out of reach answers 503. The
    client is told which, never the exception's text: that goes to the log.
    """
    try:
        idinfo = await asyncio.to_thread(_verify_id_token, token)
        return {
            "sub": idinfo["sub"],  # Google's unique user ID
            "email": idinfo["email"],
            "name": idinfo.get("name"),
            "picture": idinfo.get("picture"),
            "email_verified": idinfo.get("email_verified", False),
        }
    except TransportError as err:
        logger.exception("Could not fetch Google's certificates")
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
        logger.exception("Could not reach Google's userinfo")
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
