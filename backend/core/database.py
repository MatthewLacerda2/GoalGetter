from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from backend.core.config import settings
from dotenv import load_dotenv

load_dotenv()

# Use the DATABASE_URL directly since it's already in the correct format
engine = create_async_engine(
    settings.DATABASE_URL,  # Already has postgresql+asyncpg://
    pool_size=10,
    max_overflow=100
)

AsyncSessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    autocommit=False,
    autoflush=False,
)

async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()