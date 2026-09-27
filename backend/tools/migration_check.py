#!/usr/bin/env python3
"""Migration/model drift gate for the backend (`make back-migrations`).

The schema is described twice: `backend/models/` is what the code reads and
writes, `backend/alembic/versions/` is what the database is actually built
from. The tests build tables from the models, so a model changed without a
migration leaves a green suite and a deploy that breaks - the two descriptions
drift in silence. This is the gate that breaks that silence.

It does two things, in one pass, on a database that must be empty:

1. **Builds the schema from the migrations, from empty.** `alembic upgrade head`
   on a schema with nothing in it, which is the only way to know the history
   still runs on the database production will start from.
2. **Compares that schema with the models.** `alembic check` autogenerates
   against it and fails if there is anything to generate.

The database is `TEST_DATABASE_URL`, which `make back-migrations` sets to a
Postgres started for this run and removed after it (`tools/test-db.sh`, #205).
One that is not empty is refused rather than reset
(`backend/tools/disposable_database.py`): nothing here drops anything, and
nothing here ever touches `DATABASE_URL`.

Usage::

    python -m backend.tools.migration_check              # the gate
    python -m backend.tools.migration_check --revision "what changed"

``--revision`` is the fix for a red gate rather than part of it: same prepared
database, but autogenerate writes the new revision to
``backend/alembic/versions/`` instead of failing. Read what it wrote - a
generated revision is a draft (see the first one's docstring for what had to be
corrected by hand).
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path

from backend.core.config import settings
from backend.tools.disposable_database import alembic_url, require_empty

ALEMBIC_INI = Path(__file__).resolve().parent.parent / "alembic.ini"

MISSING_URL = (
    "TEST_DATABASE_URL is not set, so there is no database this gate is allowed "
    "to build on. Run it as `make back-migrations`, which starts a disposable one."
)


def alembic(url: str, *args: str) -> int:
    """Run one alembic command against `url`, inheriting stdout and stderr.

    A subprocess, and the URL passed as DATABASE_URL in its environment: that
    is the one knob `backend/alembic/env.py` reads, and an environment variable
    beats the .env file it would otherwise find.
    """
    completed = subprocess.run(
        [sys.executable, "-m", "alembic", "-c", str(ALEMBIC_INI), *args],
        env={**os.environ, "DATABASE_URL": url},
    )
    return completed.returncode


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--revision",
        metavar="MESSAGE",
        help="autogenerate a revision for what the models have that the migrations do not",
    )
    args = parser.parse_args(argv[1:])

    if not settings.TEST_DATABASE_URL:
        print(MISSING_URL, file=sys.stderr)
        return 1
    require_empty(settings.TEST_DATABASE_URL)
    url = alembic_url(settings.TEST_DATABASE_URL)

    failed = alembic(url, "upgrade", "head")
    if failed:
        print(
            "\nThe migrations do not build the schema from empty. Fix "
            "backend/alembic/versions/ - this is what a deploy runs.",
            file=sys.stderr,
        )
        return 1

    if args.revision:
        failed = alembic(url, "revision", "--autogenerate", "-m", args.revision)
        if not failed:
            print(
                "\nRead the revision it wrote, then `make back-fix` to sort and format it.",
            )
        return failed

    if alembic(url, "check"):
        print(
            "\nThe models and the migrations disagree: the schema above exists in "
            "backend/models/ and in no revision. Write one - "
            '`make back-revision M="what changed"` drafts it - and read it before '
            "committing.",
            file=sys.stderr,
        )
        return 1
    print("Migrations build the current schema, and match the models.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
