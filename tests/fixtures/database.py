import pytest_asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import NullPool
from sqlalchemy import text
from backend.models.base import Base
from backend.core.config import settings

# Ensure TEST_DATABASE_URL is set
if not settings.TEST_DATABASE_URL:
    raise ValueError(
        "TEST_DATABASE_URL must be set in environment variables or .env file. "
        "Example: postgresql+asyncpg://postgres:password@localhost:5432/goalgetter_test"
    )

# Use test database URL from settings
# Use NullPool to avoid connection pooling issues with asyncpg
test_engine = create_async_engine(
    settings.TEST_DATABASE_URL,
    poolclass=NullPool
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
        # Enable pgvector extension (required for VECTOR columns)
        await conn.execute(text('CREATE EXTENSION IF NOT EXISTS vector'))
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

@pytest_asyncio.fixture
async def test_db(setup_test_db):
    """Transaction rollback fixture - each test gets isolated session"""
    # Get a connection from the engine
    conn = await test_engine.connect()
    # Explicitly start a transaction on the connection
    trans = await conn.begin()
    
    try:
        # Create session bound to the connection with the active transaction
        # This ensures the session uses the existing transaction instead of trying to start a new one
        session = AsyncSession(
            bind=conn,
            expire_on_commit=False,
            autocommit=False,
            autoflush=False
        )
        
        try:
            yield session
        finally:
            # Close the session first
            await session.close()
    finally:
        # Rollback the transaction to undo all test changes
        await trans.rollback()
        # Close the connection
        await conn.close()
