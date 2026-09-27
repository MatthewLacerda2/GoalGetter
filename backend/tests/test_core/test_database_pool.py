"""Every process's pool together fits under Postgres's connection limit (#219).

The sum is written out in backend/core/config.py next to the numbers; this is
the same sum, redone from what actually runs - the engine's pool and the worker
count in docker-compose.yml - so raising either without redoing it goes red.
"""

import re
from pathlib import Path

from backend.core.config import settings
from backend.core.database import engine

COMPOSE = Path(__file__).resolve().parents[3] / "docker-compose.yml"

# Postgres's default. The compose file does not raise it; the test below checks
# that it does not lower it either.
MAX_CONNECTIONS = 100

# Processes other than the API's workers that open a pool of the app's own:
# `nightly`, the preview backend on 8001, and one run by hand (config.py).
OTHER_APP_PROCESSES = 3
MIGRATE = 1  # alembic runs on a NullPool
PSQL_AND_SPARE = 20  # never spend the last of them


def _api_workers() -> int:
    return int(re.search(r"--workers (\d+)", COMPOSE.read_text()).group(1))


def test_the_engine_is_built_from_the_settings():
    assert engine.pool.size() == settings.DB_POOL_SIZE
    assert engine.pool._max_overflow == settings.DB_MAX_OVERFLOW


def test_every_process_fits_under_max_connections():
    per_process = engine.pool.size() + engine.pool._max_overflow
    processes = _api_workers() + OTHER_APP_PROCESSES
    assert processes * per_process + MIGRATE + PSQL_AND_SPARE <= MAX_CONNECTIONS


def test_compose_leaves_max_connections_at_its_default():
    assert "max_connections" not in COMPOSE.read_text()
