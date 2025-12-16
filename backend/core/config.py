from functools import lru_cache
from pydantic import ConfigDict
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "GoalGetter"
    
    GEMINI_API_KEY: str = "AIzaSyAIHSWjJHGtnMuYiJyFK3YXYtIGkpH9eRc"
    GOOGLE_REDIRECT_URI: str
    SECRET_KEY: str
    
    DATABASE_URL: str
    TEST_DATABASE_URL: str | None = None  # Optional, only needed for tests
    
    model_config = ConfigDict(
        case_sensitive=True, 
        env_file=".env",
        env_file_encoding='utf-8',
        extra="ignore"
    )

@lru_cache()
def get_settings() -> Settings:
    return Settings()

settings = get_settings()