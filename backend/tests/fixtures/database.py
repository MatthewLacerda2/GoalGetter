"""The test database: disposable, and built by the migrations (#205).

`make back-test` starts a Postgres for the run (`tools/test-db.sh`) and hands its
URL over as TEST_DATABASE_URL. The session fixture checks the database is empty,
runs `alembic upgrade head` on it - the schema production gets, not one drawn
from the models - and every test then runs inside a transaction that is rolled
back. Nothing is dropped at the end: the container goes, and the database with it.
"""

from pathlib import Path
from unittest.mock import patch

import pytest
import pytest_asyncio
from alembic import command
from alembic.config import Config
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.pool import NullPool

from backend.core.config import settings
from backend.tools.disposable_database import alembic_url, require_empty

ALEMBIC_INI = Path(__file__).resolve().parents[2] / "alembic.ini"

MISSING_URL = (
    "TEST_DATABASE_URL is not set. The suite runs on a database started for the "
    "run: `make back-test` starts one."
)

# NullPool: every test opens and closes its own connection, so no connection
# outlives the event loop it was made on. Creating the engine opens nothing, so
# a run without a database (the live suite) never touches it.
test_engine = create_async_engine(
    settings.TEST_DATABASE_URL or "postgresql+asyncpg://unset/unset", poolclass=NullPool
)


def migrate(url: str) -> None:
    """`alembic upgrade head` on `url`, in-process, with alembic.ini's settings.

    env.py reads the target from `settings.DATABASE_URL` at call time, which in
    the test process is a host that cannot resolve (fixtures/network.py) - so it
    is pointed at the test database for exactly the length of the upgrade.
    """
    config = Config(str(ALEMBIC_INI))
    config.attributes["configure_logger"] = False
    with patch.object(settings, "DATABASE_URL", alembic_url(url)):
        command.upgrade(config, "head")


@pytest.fixture(scope="session")
def setup_test_db():
    """Migrate the run's database once. Refuses one that is not empty."""
    if not settings.TEST_DATABASE_URL:
        pytest.fail(MISSING_URL, pytrace=False)
    require_empty(settings.TEST_DATABASE_URL)
    migrate(settings.TEST_DATABASE_URL)


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
        session = AsyncSession(bind=conn, expire_on_commit=False, autocommit=False, autoflush=False)

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
