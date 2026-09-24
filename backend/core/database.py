from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from backend.core.config import settings

load_dotenv()

engine = create_async_engine(
    settings.DATABASE_URL,  # Already has postgresql+asyncpg://
    pool_size=10,
    max_overflow=100,
)

# expire_on_commit=False: endpoints read what they just committed (the new id,
# the stored row) to build their response. With the default, every attribute
# expires on commit and the read lazy-loads outside the async greenlet, which
# raises MissingGreenlet - a 500 the tests never saw, because their session
# already set it. Keep the two the same.
AsyncSessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
