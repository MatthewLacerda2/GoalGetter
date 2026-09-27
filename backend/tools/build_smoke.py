#!/usr/bin/env python3
"""Build smoke for the backend (`make back-build`): does the app still assemble,
and does it still serve the API the committed snapshot says it does?

Python has no compiler, so nothing tells us a module stopped importing until
something imports it. Importing `backend.main` walks every router, model,
schema and service the app wires up, and `app.openapi()` then forces FastAPI to
resolve every route's request and response model. A broken import, a schema
that no longer validates, a route whose response model references a deleted
type - all of it surfaces here, in about a second, with no database.

The OpenAPI it generates is then written to `backend/openapi.json`, which is
committed (#213). When the file changed, the gate fails: the API moved and the
snapshot was not regenerated with it. The rewrite has already happened by then,
so the fix is to read `git diff backend/openapi.json` and commit it - and that
diff is how every API change shows up in a pull request. The frontend reads the
same file (`frontend/test/contract/`) and fails when a route it calls or a
fixture it answers with no longer matches.

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

import json
import os
from collections.abc import Mapping
from pathlib import Path

# Settings are required fields (backend/core/config.py), so give them values
# before the import chain reaches them. These are deliberately useless: a URL
# that resolves to nothing, keys that are not keys. `os.environ` wins over
# `.env` in pydantic-settings, so this also guarantees the smoke can never be
# pointed at the real database by a `.env` that happens to be present.
#
# DEV_LOGIN is pinned off for the snapshot's sake: it decides whether
# POST /auth/dev-login is in the schema (`include_in_schema`), and the snapshot
# describes what production serves, whatever this machine's `.env` says.
PLACEHOLDERS = {
    "DATABASE_URL": "postgresql+asyncpg://build:smoke@127.0.0.1:1/build_smoke",
    "TEST_DATABASE_URL": "postgresql+asyncpg://build:smoke@127.0.0.1:1/build_smoke",
    "GEMINI_API_KEY": "build-smoke",
    "SECRET_KEY": "build-smoke",
    "DEV_LOGIN": "false",
}

HTTP_METHODS = {"get", "put", "post", "delete", "options", "head", "patch", "trace"}

SNAPSHOT = Path(__file__).resolve().parents[1] / "openapi.json"


def render(schema: Mapping[str, object]) -> str:
    """The snapshot's text: FastAPI's own key order (routes read in the order
    the routers declare them), indented so a diff names the line that moved."""
    return json.dumps(schema, indent=2, ensure_ascii=False) + "\n"


def write_snapshot(schema: Mapping[str, object], path: Path = SNAPSHOT) -> bool:
    """Writes the snapshot; True when the committed copy was already current."""
    text = render(schema)
    current = path.read_text(encoding="utf-8") if path.exists() else None
    if current != text:
        path.write_text(text, encoding="utf-8")
    return current == text


def main() -> int:
    os.environ.update(PLACEHOLDERS)

    from backend.main import app

    schema = app.openapi()
    # Counted from the OpenAPI, not `app.routes`: FastAPI 0.141 keeps each
    # included router as one entry there, so that number stopped moving when an
    # endpoint went away (#170). An operation is one method on one path.
    paths = schema.get("paths", {})
    operations = sum(1 for item in paths.values() for key in item if key in HTTP_METHODS)
    if not write_snapshot(schema):
        print(
            "backend/openapi.json did not match the API and has been rewritten.\n"
            "The API changed: read `git diff backend/openapi.json` and commit it."
        )
        return 1
    print(f"backend build OK - {operations} operations on {len(paths)} paths, snapshot current")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
