import os
from pathlib import Path
from functools import lru_cache
from pydantic import ConfigDict
from pydantic_settings import BaseSettings

# Calculate the root path of the project (3 levels up from backend/core/config.py)
ROOT_DIR = Path(__file__).resolve().parent.parent.parent
ROOT_ENV = ROOT_DIR / ".env"

class Settings(BaseSettings):
    
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "GoalGetter"
    
    GEMINI_API_KEY: str
    GOOGLE_REDIRECT_URI: str
    SECRET_KEY: str
    GOOGLE_CLIENT_ID: str = ""
    GOOGLE_PROJECT_ID: str = ""
    
    DATABASE_URL: str
    TEST_DATABASE_URL: str | None = None  # Optional, only needed for tests
    
    model_config = ConfigDict(
        case_sensitive=True, 
        env_file=str(ROOT_ENV),
        env_file_encoding='utf-8',
        extra="ignore"
    )

@lru_cache()
def get_settings() -> Settings:
    return Settings()

settings = get_settings()