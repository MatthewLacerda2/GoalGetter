"""The repository gate looks at what code does, not at how it is spelled (#211).

Each case in `BYPASSES` went through the gate while it matched variable names
(`db`, `session`) and import spellings (`from sqlalchemy import select`): an
alias, `text()`, and a session kept under another name all reached the
database from outside repositories/.
"""

import textwrap

import pytest

from backend.tests.backend_linter import check_source

SERVICE = "backend/services/example.py"
REPOSITORY = "backend/repositories/example_repository.py"

BYPASSES = {
    "the package under an alias": """
        import sqlalchemy as sa

        QUERY = sa.select(1)
        """,
    "text()": """
        from sqlalchemy import text

        QUERY = text("SELECT 1")
        """,
    "self.session.execute": """
        class Store:
            def __init__(self, session):
                self.session = session

            async def rows(self, query):
                return await self.session.execute(query)
        """,
    "self.session.add": """
        class Store:
            def __init__(self, session):
                self.session = session

            def save(self, row):
                self.session.add(row)
        """,
    "a typed session under any name": """
        from sqlalchemy.ext.asyncio import AsyncSession

        class Store:
            def __init__(self, store: AsyncSession):
                self.store = store

            def save(self, row):
                self.store.add(row)
        """,
    "a session opened from the factory": """
        from backend.core.database import AsyncSessionLocal

        async def save(row):
            async with AsyncSessionLocal() as s:
                s.add(row)
        """,
    "execute on anything": """
        async def rows(conn, query):
            return await conn.execute(query)
        """,
    "a submodule's construct": """
        from sqlalchemy.sql.expression import select
        """,
    "an import by string": """
        import importlib

        sa = importlib.import_module("sqlalchemy")
        """,
}

NOT_DATABASE_ACCESS = {
    "the session type, for Depends": """
        from fastapi import Depends
        from sqlalchemy.ext.asyncio import AsyncSession

        from backend.core.database import get_db

        async def endpoint(db: AsyncSession = Depends(get_db)):
            await db.commit()
        """,
    "an exception, to catch": """
        from sqlalchemy.exc import DBAPIError
        """,
    "a set's add": """
        def unique(links):
            seen = set()
            for link in links:
                seen.add(link)
            return seen
        """,
    "a repository's delete": """
        async def remove(db, goal_id):
            await GoalRepository(db).delete(goal_id)
        """,
    "a dict's get and an HTTP client's get": """
        async def fetch(client, cache, url):
            return cache.get(url) or await client.get(url)
        """,
}


def violations(code: str, path: str = SERVICE) -> list:
    return check_source(textwrap.dedent(code), path)


@pytest.mark.parametrize("code", BYPASSES.values(), ids=BYPASSES.keys())
def test_reaching_the_database_outside_repositories_fails(code):
    assert violations(code)


@pytest.mark.parametrize("code", BYPASSES.values(), ids=BYPASSES.keys())
def test_the_same_code_is_what_a_repository_is_for(code):
    assert violations(code, REPOSITORY) == []


@pytest.mark.parametrize("code", NOT_DATABASE_ACCESS.values(), ids=NOT_DATABASE_ACCESS.keys())
def test_what_only_looks_like_database_access_passes(code):
    assert violations(code) == []


def test_an_endpoint_is_held_to_the_same_rule():
    assert violations(BYPASSES["text()"], "backend/api/v1/endpoints/example.py")
