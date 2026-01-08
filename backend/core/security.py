import logging
from jose import jwt, JWTError
from google.oauth2 import id_token
from google.auth.transport import requests
from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from backend.core.config import settings
from backend.core.database import get_db
from backend.models.student import Student
from backend.repositories.student_repository import StudentRepository
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
            detail=f"ValueError: Invalid Google token. {e}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Google token"
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
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token"
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
                detail=f"Invalid token payload"
            )
        
        student_repo = StudentRepository(db)
        user = await student_repo.get_by_google_id(user_id)
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User not found"
            )
            
        return user
        
    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Could not validate credentials"
        )

async def verify_google_token_header(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> dict:
    """
    Verify a Google OAuth2 token from the Authorization header.
    Returns the user info from Google without requiring the user to exist in the database.
    """
    try:
        # Extract the token from "Bearer <token>"
        google_token = credentials.credentials
        return verify_google_token(google_token)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Verify Google Token Header: Invalid Google token {e}"
        )