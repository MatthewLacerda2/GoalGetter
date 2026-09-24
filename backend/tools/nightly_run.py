#!/usr/bin/env python3
"""The night's entry point (#89, #96): a process of its own, not a scheduler
inside the API.

**Two jobs, one process, one at a time.** The night has two hours in it: the
embedding backfill at `EMBEDDING_RUN_HOUR` (midnight) and the per-student chain
at `NIGHTLY_RUN_HOUR` (03:00). The loop below sleeps to whichever comes first
and runs that one job to completion before it looks at the clock again, so the
two can never be talking to Gemini at the same time however long either takes.
Two loops under one `gather` would have been fewer lines and would have put the
backfill's calls on top of the chain's on any night the backfill ran long.

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
loop sleeps to the next hour first - both of them.

Usage::

    python -m backend.tools.nightly_run                  # wait for the next hour, forever
    python -m backend.tools.nightly_run --once           # run every student now
    python -m backend.tools.nightly_run --student <id>   # one student, now
    python -m backend.tools.nightly_run --embeddings     # fill every null embedding now

The last three are how the behaviour is watched without waiting for the hour:
every decision either job takes is logged, including the ones that skip.

**It spends real quota**, exactly as the night would.
"""

import argparse
import asyncio
import logging
import sys

from backend.core import clock
from backend.services.jobs.embeddings import run_embeddings
from backend.services.jobs.nightly import run_for_student, run_nightly

logger = logging.getLogger("backend.tools.nightly_run")


async def wait_for_the_next_job():
    """Sleep until the night's next hour and answer with the job it belongs to.

    Both hours are the clock's (`backend/core/clock.py`), so the time zone and
    the schedule are named in one place. The backfill wins a tie because it is
    the cheap job: if the two hours were ever set to the same one, the vectors
    should be in before the chain starts spending.
    """
    at_embeddings = clock.next_embedding_run()
    at_chain = clock.next_nightly_run()
    if at_embeddings <= at_chain:
        name, job, fires = "embedding backfill", run_embeddings, at_embeddings
    else:
        name, job, fires = "nightly run", run_nightly, at_chain

    seconds = (fires - clock.now()).total_seconds()
    logger.info("Next %s at %s (%.0f minutes from now)", name, fires.isoformat(), seconds / 60)
    await asyncio.sleep(max(seconds, 0))
    return name, job


async def forever() -> None:
    while True:
        name, job = await wait_for_the_next_job()
        try:
            await job()
        except Exception:
            # Both jobs already swallow the failure of one student or one batch,
            # so this is the database being unreachable or worse. Log it and
            # stay up: tomorrow night is still worth being here for.
            logger.exception("The %s failed as a whole", name)


async def main_async(args) -> int:
    if args.embeddings:
        tallies = await run_embeddings()
        filled = sum(tally.filled for tally in tallies)
        print(f"{filled} embedding(s) filled, {sum(t.left for t in tallies)} left")
        return 0
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
    parser.add_argument(
        "--embeddings", action="store_true", help="fill every null embedding now, then exit"
    )
    args = parser.parse_args(argv[1:])

    logging.basicConfig(
        level=logging.INFO, format="%(asctime)s - %(levelname)s - %(name)s - %(message)s"
    )
    return asyncio.run(main_async(args))


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
