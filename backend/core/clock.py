"""The app's clock: one time zone, one `now`, one calendar day (#92).

**Moments are stored in UTC; calendar days are the app's.** Every timestamp the
backend writes is timezone-aware UTC, and the only place a zone is applied is
where a *calendar day* is the answer - the streak's day boundary, Home's daily
elo buckets, and the hour the nightly job fires.

The alternative was to set the container's `TZ` to `America/Sao_Paulo` and let
`datetime.now()` and `astimezone()` keep reading the environment. It was
rejected for three reasons:

1. **The bug was that the code asked the environment what day it was.** The
   container ran UTC, the machine `-03`, so a lesson finished at 22:00 Brasilia
   landed on the next day. Setting `TZ` moves that dependency, it does not
   remove it: pytest, CI, the seeder and a `docker run` outside compose each
   get whatever zone their own environment happens to carry, and no test can
   pin a rule that lives in a deployment variable.
2. **Students will not all be in Brazil.** `APP_TIMEZONE` is the *default* the
   app reasons in today. When a student's own zone arrives it becomes a column
   read here, and only the functions below change. With `TZ` on the container,
   a student outside Brazil would need the whole process to lie.
3. **UTC in the column is unambiguous.** `timestamptz` plus an aware value
   survives a zone change, a DST transition and a move to another machine;
   `America/Sao_Paulo` through `zoneinfo` also gets Brazil's historical DST
   right, which a hardcoded `-03` would not.

So: `now()` everywhere a timestamp is written, `app_date()` everywhere a day is
counted, and nothing reads the server's zone.
"""

from datetime import UTC, date, datetime, time, timedelta
from zoneinfo import ZoneInfo

# The one time zone the app reasons in. Per-student zones can come later; this
# stays the default. Named, not an offset, so DST is the library's problem.
APP_TIMEZONE = ZoneInfo("America/Sao_Paulo")

# "My night, the computer's" (the user, 2026-09-23): the hour, in APP_TIMEZONE,
# at which the nightly jobs run. What those jobs do is #89; this is only when.
NIGHTLY_RUN_HOUR = 3


def now() -> datetime:
    """The current moment, timezone-aware, in UTC. The default of every
    timestamp column, so asyncpg is never handed a naive value to guess at."""
    return datetime.now(UTC)


def as_utc(moment: datetime) -> datetime:
    """`moment` as an aware UTC value. A naive one is read as UTC, which is how
    asyncpg already stored the naive defaults this module replaces."""
    return moment.replace(tzinfo=UTC) if moment.tzinfo is None else moment.astimezone(UTC)


def app_local(moment: datetime) -> datetime:
    """`moment` on the app's wall clock - what the hour read where the student is."""
    return as_utc(moment).astimezone(APP_TIMEZONE)


def app_date(moment: datetime) -> date:
    """The app's calendar date of a moment - the day the student lived it."""
    return app_local(moment).date()


def today() -> date:
    """The app's calendar date right now."""
    return app_date(now())


def app_moment(day: date, hour: int = 0, minute: int = 0) -> datetime:
    """`day` at `hour:minute` in APP_TIMEZONE, as an aware UTC moment."""
    local = datetime.combine(day, time(hour, minute), tzinfo=APP_TIMEZONE)
    return local.astimezone(UTC)


def next_nightly_run(after: datetime | None = None) -> datetime:
    """The next NIGHTLY_RUN_HOUR in APP_TIMEZONE strictly after `after`, in UTC.

    What waits on it is `backend/tools/nightly_run.py` (#89); the schedule
    itself lives here so that the hour is defined once and a test can pin it.
    """
    after = as_utc(after if after is not None else now())
    day = app_date(after)
    fires = app_moment(day, NIGHTLY_RUN_HOUR)
    if fires <= after:
        fires = app_moment(day + timedelta(days=1), NIGHTLY_RUN_HOUR)
    return fires


def previous_nightly_run(before: datetime | None = None) -> datetime:
    """The last NIGHTLY_RUN_HOUR in APP_TIMEZONE strictly before `before`, in UTC.

    **This is what the nightly run means by "today" (#89).** The run fires at
    03:00, three hours into a calendar day on which nobody has studied yet - so
    reading `today()` there would skip every student who did their lesson the
    evening before, which is every student. The day the run closes out is the
    24 hours behind it, `[previous_nightly_run(at), at]`. The user's own
    framing - "the student either did today's lesson or was not going to" - is
    that day, not the calendar one.

    Strictly before, so a run at exactly 03:00 looks back over the day that
    just ended rather than at a window of zero width. Run by hand at any other
    hour it reads as one expects: everything since 03:00 this morning.
    """
    before = as_utc(before if before is not None else now())
    day = app_date(before)
    fired = app_moment(day, NIGHTLY_RUN_HOUR)
    if fired >= before:
        fired = app_moment(day - timedelta(days=1), NIGHTLY_RUN_HOUR)
    return fired
