#!/usr/bin/env python3
"""Build smoke for the backend (`make back-build`): does the app still assemble?

Python has no compiler, so nothing tells us a module stopped importing until
something imports it. Importing `backend.main` walks every router, model,
schema and service the app wires up, and `app.openapi()` then forces FastAPI to
resolve every route's request and response model. A broken import, a schema
that no longer validates, a route whose response model references a deleted
type - all of it surfaces here, in about a second, with no database.

No database is needed and none may be touched: the app has no lifespan (#157),
and importing the module never opens a connection (`create_async_engine` is
lazy). This script therefore
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

HTTP_METHODS = {"get", "put", "post", "delete", "options", "head", "patch", "trace"}


def main():
    os.environ.update(PLACEHOLDERS)

    from backend.main import app

    # Counted from the OpenAPI, not `app.routes`: FastAPI 0.141 keeps each
    # included router as one entry there, so that number stopped moving when an
    # endpoint went away (#170). An operation is one method on one path.
    paths = app.openapi().get("paths", {})
    operations = sum(1 for item in paths.values() for key in item if key in HTTP_METHODS)
    print(f"backend build OK - {operations} operations on {len(paths)} paths")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
