from datetime import datetime, timedelta, UTC
from typing import Optional
from jose import jwt, JWTError
from google.oauth2 import id_token
from google.auth.transport import requests
from fastapi import HTTPException, status, Depends, Security
from fastapi.security import HTTPBearer, APIKeyHeader, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from backend.core.config import settings
from backend.core.database import get_db
from backend.models.student import Student
from sqlalchemy import select
import logging
from backend.utils.envs import JWT_ISSUER, JWT_AUDIENCE, GOOGLE_CLIENT_ID

logger = logging.getLogger(__name__)

def create_access_token(data: dict) -> str:
    """
    Create a JWT access token with the given data and expiration time.
    """
    to_encode = data.copy()
    
    
    to_encode.update({
        "iss": JWT_ISSUER,  # Add issuer claim
        "aud": JWT_AUDIENCE  # Add audience claim
    })
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm="HS256")
    return encoded_jwt

def verify_google_token(token: str) -> dict:
    """
    Verify a Google OAuth2 token and return the user information.
    
    Args:
        token: The Google OAuth2 access token
        
    Returns:
        dict: User information from Google
        
    Raises:
        HTTPException: If the token is invalid or verification fails
    """
    try:
        idinfo = id_token.verify_oauth2_token(
            token,
            requests.Request(),
            GOOGLE_CLIENT_ID
        )
        
        # Check if the token was issued to our client
        if idinfo['aud'] != GOOGLE_CLIENT_ID:
            raise ValueError("Token was not issued for this client")
            
        return {
            "sub": idinfo["sub"],  # Google's unique user ID
            "email": idinfo["email"],
            "name": idinfo.get("name"),
            "picture": idinfo.get("picture"),
            "email_verified": idinfo.get("email_verified", False)
        }
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"ValueError, Invalid Google token at verify_google_token value error: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Exception, Invalid Google token at verify_google_token exception: {str(e)}"
        )

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
            audience=JWT_AUDIENCE
        )
        return payload
    except JWTError as e:
        logger.error(f"JWTError, Invalid token at verify_token: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"JWTError, Invalid token at verify_token: {e}"
        )

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db)
) -> Student:
    """
    Get the current authenticated user from the JWT token.
    """
    try:
        payload = verify_token(credentials.credentials)
        
        # Get user_id from token payload
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Invalid token payload at get_current_user: {e}"
            )
            
        stmt = select(Student).where(Student.id == user_id)
        result = await db.execute(stmt)
        user = result.scalar_one_or_none()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User not found at get_current_user: {e}"
            )
            
        return user
        
    except JWTError as e:
        logger.error(f"JWTError, Invalid token at get_current_user: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"JWTError, Invalid token at get_current_user: {e}"
        )
    except Exception as e:
        logger.error(f"Exception, Could not validate credentials at get_current_user: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Exception, Could not validate credentials at get_current_user: {e}"
        )

api_key_header = APIKeyHeader(name="X-API-Key")

async def get_user_by_api_key(
    api_key: str = Security(api_key_header),
    db: AsyncSession = Depends(get_db)
) -> Student:
    """
    Get the current user based on their API key from the X-API-Key header.
    """
    stmt = select(Student).where(Student.api_key == api_key)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid API key at get_user_by_api_key: {api_key}"
        )
        
    return user
