#!/usr/bin/env python3
"""Whole-program dead-code gate for the backend (`make back-deadcode`).

Ruff's pyflakes rules, which `make back-lint` enforces, catch *file-local* dead
code: an unused import, an unused local. What they cannot see is a function,
class or method that no other module references - that needs whole-program
analysis, and vulture provides it.

This project has been bitten by exactly that: `core/scheduler.py` sat in the
tree wiring four cron jobs whose modules had been deleted, every import broken,
and nothing noticed until a human read the file.

Vulture is name-based and purely static, so this wrapper carries the policy
that makes its output trustworthy:

1. **Only structural findings gate.** Functions, classes, methods, properties,
   attributes and unreachable code block the build. ``variable`` findings are
   dropped wholesale: at class level they are SQLAlchemy columns, Pydantic
   fields and enum members consumed by name through the ORM or the JSON
   serializer - invisible to any static analyzer - while an unused *local* is
   already a ruff F841 error and an unused *parameter* usually matches a
   signature that is mocked or overridden on purpose.
2. **Framework entry points are not dead.** Route handlers and pytest fixtures
   are invoked by decorator convention (``IGNORE_DECORATORS``); a handful of
   names a framework reads dynamically are listed in ``IGNORE_NAMES``, each
   with the reason it is there.
3. **``backend/alembic`` is excluded.** ``upgrade`` / ``downgrade`` and the
   ``revision`` module globals are called and read by alembic itself, by name
   convention, so every migration would report as dead.

``backend/tests`` is scanned as a *consumer*: a symbol referenced only by a
test still counts as used. That is deliberate - the gate is here to find code
nothing reaches, not to police what tests cover.

The whitelist is the weak point of a gate like this: an entry that silences
real dead code is worse than no gate at all. Keep it as short as it can be, and
never add one without the comment saying who calls the name.

Usage::

    python -m backend.tools.deadcode [--warn] [path ...]   # defaults to "backend"

Prints one ``path:line: message`` per finding and exits 1 if there are any.
``--warn`` reports and exits 0, for local triage without failing the run.
"""

import argparse
import sys

from vulture import Vulture

# Below 60, vulture starts guessing; at 60 and above a finding is worth reading.
MIN_CONFIDENCE = 60

# fnmatch patterns matched against the decorator's source text. A name wearing
# one of these is an entry point some framework calls for us, and is never dead
# merely because no project code names it.
IGNORE_DECORATORS = [
    "@*router.*",  # FastAPI route handlers: @router.get(...), @router.post(...)
    "@app.*",  # app-level routes and hooks in backend/main.py
    "@pytest.fixture",  # fixtures are requested by parameter name, never referenced
    "@pytest_asyncio.fixture",
    "@field_validator",  # Pydantic v2 validators run during (de)serialization
    "@model_validator",
]

# Names read dynamically: vulture cannot see a getattr string, nor a framework
# calling a method it knows by convention. Every entry names its caller. Four
# is the whole list on purpose - a fifth should be argued for, not added.
IGNORE_NAMES = [
    # Starlette calls this override on every request (core/logging_middleware.py).
    "dispatch",
    # A SQLAlchemy column on Student. The endpoints write it; the only reader is
    # the database, which no static analyzer can see.
    "last_login",
    # unittest.mock reads both off the mock object it hands the test. Every
    # `mock.return_value = ...` in the suite would otherwise report as dead.
    "return_value",
    "side_effect",
]

# fnmatch patterns matched against file paths.
EXCLUDE = ["*/alembic/*", "*/venv/*", "*/.venv/*", "*/__pycache__/*"]


def gated(items):
    """Keep the finding kinds the gate blocks on (policy point 1 above)."""
    return [item for item in items if item.typ != "variable"]


def collect(paths):
    vulture = Vulture(ignore_names=IGNORE_NAMES, ignore_decorators=IGNORE_DECORATORS)
    vulture.scavenge(paths, exclude=EXCLUDE)
    return gated(vulture.get_unused_code(min_confidence=MIN_CONFIDENCE))


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("paths", nargs="*", default=["backend"])
    parser.add_argument("--warn", action="store_true", help="report findings but exit 0")
    args = parser.parse_args(argv[1:])

    findings = collect(args.paths or ["backend"])
    for item in findings:
        print(item.get_report())
    if findings:
        label = "warning" if args.warn else "error"
        print(
            f"\n{len(findings)} dead-code finding(s) ({label}). Delete the code; or, if a "
            f"framework calls it for us, add it to IGNORE_DECORATORS / IGNORE_NAMES in "
            f"backend/tools/deadcode.py with the reason.",
            file=sys.stderr,
        )
        return 0 if args.warn else 1
    print("No dead code found.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
