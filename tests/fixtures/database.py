import pytest_asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from backend.models.base import Base
from backend.core.config import settings

# Ensure TEST_DATABASE_URL is set
if not settings.TEST_DATABASE_URL:
    raise ValueError(
        "TEST_DATABASE_URL must be set in environment variables or .env file. "
        "Example: postgresql+asyncpg://postgres:password@localhost:5432/goalgetter_test"
    )

# Use test database URL from settings
test_engine = create_async_engine(
    settings.TEST_DATABASE_URL,
    pool_size=5,
    max_overflow=10
)

TestingSessionLocal = sessionmaker(
    test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

@pytest_asyncio.fixture(scope="session")
async def setup_test_db():
    """Create tables once at session start, drop at end"""
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

@pytest_asyncio.fixture
async def test_db(setup_test_db):
    """Transaction rollback fixture - each test gets isolated session"""
    async with test_engine.connect() as conn:
        transaction = await conn.begin()
        session = AsyncSession(bind=conn, expire_on_commit=False)
        try:
            yield session
        finally:
            await session.close()
            await transaction.rollback()
