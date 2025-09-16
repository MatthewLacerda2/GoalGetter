from pydantic_settings import BaseSettings
from pydantic import ConfigDict
from functools import lru_cache

class Settings(BaseSettings):
    
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "GoalGetter"
    #TODO: all values below are made-up
    DATABASE_URL: str = "postgresql+asyncpg://localhost/goalgetter" #TODO: read from .env
    GOOGLE_REDIRECT_URI: str = "http://localhost:8000/api/v1/auth/google/callback" #TODO: read from .env
    
    GEMINI_API_KEY: str
    
    SECRET_KEY: str = "09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7"
    
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