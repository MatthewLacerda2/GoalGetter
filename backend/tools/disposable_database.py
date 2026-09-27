"""The rule every user of the disposable test database keeps: it builds
only on a database that is empty.

`tools/test-db.sh` starts a Postgres for one run, so the database the pytest
fixtures and `make back-migrations` receive was born seconds ago with nothing in
it. Checking that is what turns "the tests use a throwaway database" from a
convention into a guarantee: a TEST_DATABASE_URL that names a database holding
anything at all - the live one, the long-lived compose `postgres_test`, a run
that somehow survived - is refused before a single statement changes it. So
nothing here ever drops, truncates or resets anything; the container's removal is
the only undo there is.
"""

import psycopg2

REFUSED = (
    "TEST_DATABASE_URL names a database that already holds {count} relation(s) in "
    "its public schema. The tests and the migration gate build only on a database "
    "born empty for this run and thrown away after it, and refuse any other. Run "
    "them through `make back-test` / `make back-migrations`, which start one."
)


def alembic_url(url: str) -> str:
    """The psycopg2 form of an asyncpg URL: alembic drives a plain DBAPI."""
    return url.replace("postgresql+asyncpg://", "postgresql+psycopg2://")


def require_empty(url: str) -> None:
    """Raise unless the database at `url` has nothing in its public schema."""
    libpq = url.replace("postgresql+asyncpg://", "postgresql://").replace(
        "postgresql+psycopg2://", "postgresql://"
    )
    connection = psycopg2.connect(libpq)
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT count(*) FROM pg_class c JOIN pg_namespace n "
                "ON n.oid = c.relnamespace WHERE n.nspname = 'public'"
            )
            (count,) = cursor.fetchone()
    finally:
        connection.close()
    if count:
        raise RuntimeError(REFUSED.format(count=count))
