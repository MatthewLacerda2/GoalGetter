#!/usr/bin/env python3
"""The nightly run's entry point (#89): a process of its own, not a scheduler
inside the API.

**Why a process and not an in-process scheduler.** The API is served by four
uvicorn workers (`docker-compose.yml`), and every one of them is a separate
Python process with its own event loop. An APScheduler wired into the app would
fire in all four at 03:00: four chains for the same student, four sets of
Gemini calls racing each other, four banks written. Electing a leader among the
workers means a lock table and a heartbeat - a distributed-systems problem
bought to run one job once a day. There is exactly one of this process, so
there is exactly one run.

**Why a compose service and not the host's cron.** The deployment is this
machine's `docker compose up`, rebuilt from `main` on every merge (CLAUDE.md).
A cron entry lives outside the repository: it is not reviewed, does not arrive
with the code that needs it, and would have to be installed by hand on any
machine the app is ever brought up on - including after a reinstall, when
nobody would remember. A service in `docker-compose.yml` ships with the change
that needs it, reads the same environment as the API, and is restarted by the
same `restart: unless-stopped`. The trade is that a missed 03:00 - the machine
asleep, the stack down - is simply missed; there is no catch-up, because a
catch-up needs to remember when it last ran, and remembering means a column
this issue did not ask for.

**It waits before it runs, never after.** `restart: unless-stopped` plus a run
on startup would spend real quota on every deploy and every crash loop. So the
loop sleeps to the next 03:00 first.

Usage::

    python -m backend.tools.nightly_run                  # wait for 03:00, forever
    python -m backend.tools.nightly_run --once           # run every student now
    python -m backend.tools.nightly_run --student <id>   # one student, now

The last two are how the behaviour is watched without waiting for 03:00: every
decision the run takes is logged, including the ones that skip.

**It spends real quota**, exactly as the night would.
"""

import argparse
import asyncio
import logging
import sys

from backend.core import clock
from backend.services.jobs.nightly import run_for_student, run_nightly

logger = logging.getLogger("backend.tools.nightly_run")


async def wait_for_the_hour() -> None:
    """Sleep until the next NIGHTLY_RUN_HOUR. The hour itself is the clock's
    (`backend/core/clock.py`), so the time zone is named in one place."""
    fires = clock.next_nightly_run()
    seconds = (fires - clock.now()).total_seconds()
    logger.info("Next nightly run at %s (%.0f minutes from now)", fires.isoformat(), seconds / 60)
    await asyncio.sleep(max(seconds, 0))


async def forever() -> None:
    while True:
        await wait_for_the_hour()
        try:
            await run_nightly()
        except Exception:
            # run_nightly already swallows a single student's failure, so this
            # is the database being unreachable or worse. Log it and stay up:
            # tomorrow night is still worth being here for.
            logger.exception("Nightly run failed as a whole")


async def main_async(args) -> int:
    if args.student:
        ran = await run_for_student(args.student)
        print(f"student {args.student}: {'chain ran' if ran else 'skipped'}")
        return 0
    if args.once:
        looked_at, ran = await run_nightly()
        print(f"{ran} of {looked_at} students had a chain run")
        return 0
    await forever()
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--once", action="store_true", help="run every student now, then exit")
    parser.add_argument("--student", help="run for this student id now, then exit")
    args = parser.parse_args(argv[1:])

    logging.basicConfig(
        level=logging.INFO, format="%(asctime)s - %(levelname)s - %(name)s - %(message)s"
    )
    return asyncio.run(main_async(args))


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
