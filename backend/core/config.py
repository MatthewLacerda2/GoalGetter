from pydantic_settings import BaseSettings
from pydantic import ConfigDict
from functools import lru_cache

class Settings(BaseSettings):
    
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "GoalGetter"
    
    GEMINI_API_KEY: str  # No default value - must be set in .env
    
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