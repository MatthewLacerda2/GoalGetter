"""`python -m backend.services.fictitious [--fresh]`, what `make claude` runs.

Writes to the database in DATABASE_URL (an environment variable overrides
.env). The schema must already exist: a backend creates it on start.
"""

import argparse
import asyncio
import sys

from sqlalchemy.exc import DBAPIError, ProgrammingError

from backend.core.database import AsyncSessionLocal, engine
from backend.services.fictitious.seeder import seed_fictitious_student


async def main(fresh: bool) -> int:
    try:
        async with AsyncSessionLocal() as db:
            result = await seed_fictitious_student(db, fresh=fresh)
    except ProgrammingError:
        print(
            "claude: the tables are missing. Start the backend once (it creates the schema), then re-run.",
            file=sys.stderr,
        )
        return 1
    except (DBAPIError, OSError) as error:
        print(f"claude: cannot reach the database ({type(error).__name__}).", file=sys.stderr)
        return 1
    finally:
        await engine.dispose()

    names = ", ".join(goal.name for goal in result.goals)
    if result.created:
        print(f"claude: seeded {result.student.name} with {len(result.goals)} goals: {names}.")
    else:
        print(
            f"claude: {result.student.name} already has its history ({names}); nothing written. "
            "ARGS=--fresh rebuilds it."
        )
    print(
        "  The backend drops its schema on every start: a restart wipes this history. Re-run `make claude` then."
    )
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Give Fictitious Claude a lived-in history.")
    parser.add_argument("--fresh", action="store_true", help="delete the student and rebuild it")
    sys.exit(asyncio.run(main(parser.parse_args().fresh)))
