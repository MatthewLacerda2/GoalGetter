#!/usr/bin/env python3
"""Build smoke for the backend (`make back-build`): does the app still assemble?

Python has no compiler, so nothing tells us a module stopped importing until
something imports it. Importing `backend.main` walks every router, model,
schema and service the app wires up, and `app.openapi()` then forces FastAPI to
resolve every route's request and response model. A broken import, a schema
that no longer validates, a route whose response model references a deleted
type - all of it surfaces here, in about a second, with no database.

No database is needed and none may be touched: the lifespan that drops and
recreates the schema only runs when a server starts, and importing the module
never opens a connection (`create_async_engine` is lazy). This script therefore
pins placeholder settings *before* the import, so the app assembles against
values that point nowhere even if a real `.env` sits next to it - and
`make back-build` runs the container with no network at all, so a connection
attempt would fail rather than reach the dev database by accident.

Usage::

    python -m backend.tools.build_smoke
"""

import os

# Settings are required fields (backend/core/config.py), so give them values
# before the import chain reaches them. These are deliberately useless: a URL
# that resolves to nothing, keys that are not keys. `os.environ` wins over
# `.env` in pydantic-settings, so this also guarantees the smoke can never be
# pointed at the real database by a `.env` that happens to be present.
PLACEHOLDERS = {
    "DATABASE_URL": "postgresql+asyncpg://build:smoke@127.0.0.1:1/build_smoke",
    "TEST_DATABASE_URL": "postgresql+asyncpg://build:smoke@127.0.0.1:1/build_smoke",
    "GEMINI_API_KEY": "build-smoke",
    "SECRET_KEY": "build-smoke",
    "GOOGLE_REDIRECT_URI": "http://localhost/callback",
}


def main():
    os.environ.update(PLACEHOLDERS)

    from backend.main import app

    schema = app.openapi()
    paths = len(schema.get("paths", {}))
    print(f"backend build OK - {len(app.routes)} routes, {paths} documented paths")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
