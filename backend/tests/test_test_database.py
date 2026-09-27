"""The suite's database is disposable, migrated, and the only one it can open (#205)."""

import pytest
from alembic.config import Config
from alembic.script import ScriptDirectory
from sqlalchemy import text

from backend.core.config import settings
from backend.core.database import AsyncSessionLocal, engine
from backend.tests.fixtures.database import ALEMBIC_INI
from backend.tests.fixtures.environment import UNREACHABLE_HOST
from backend.tests.fixtures.network import NetworkCallInDefaultSuite
from backend.tools.disposable_database import require_empty


def test_the_test_process_holds_no_real_database_url():
    assert engine.url.host == UNREACHABLE_HOST
    assert UNREACHABLE_HOST in settings.DATABASE_URL


async def test_an_unpatched_session_fails_loudly_and_reaches_nothing(network_attempts):
    """What the chain, the nightly run and the embeddings job open for
    themselves, opened by a test that forgot to hand them its own."""
    with pytest.raises(NetworkCallInDefaultSuite, match="AsyncSessionLocal"):
        async with AsyncSessionLocal() as session:
            await session.connection()

    assert network_attempts == [UNREACHABLE_HOST]
    network_attempts.clear()


async def test_the_schema_is_the_migrations_head(test_db):
    head = ScriptDirectory.from_config(Config(str(ALEMBIC_INI))).get_current_head()

    version = (await test_db.execute(text("SELECT version_num FROM alembic_version"))).scalar()

    assert version == head


def test_a_database_that_holds_anything_is_refused(setup_test_db):
    """The run's own database, migrated a moment ago, is no longer empty - so
    neither the fixtures nor the migration gate would build on it again."""
    with pytest.raises(RuntimeError, match="born empty for this run"):
        require_empty(settings.TEST_DATABASE_URL or "")
