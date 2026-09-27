"""The study streak: user-wide, computed from answers, never stored.

A day is **studied** when the student answered at least one question that day,
on any goal - there is no lesson row to have finished (#131). Days are the
app's calendar days, in `core.clock.APP_TIMEZONE`, never the server's zone
(#92), which made an answer given at 22:00 Brasilia count for the next day.

**The rule (#204, the user, 2026-09-26): he may miss two days in a week and
keep his streak; the third missed day in that week resets it** - like
Duolingo. A streak lost to one busy day is a reason not to come back, and
coming back is the metric. The rule left two readings open, taken as the issue
proposed:

- **A week is the calendar week, Monday to Sunday**, in the app's zone: the
  simplest for a student to hold in his head ("I still have a day off this
  week"). So two days missed on a weekend and two more on the Monday and
  Tuesday after it all keep the streak - they fall in two weeks.
- **A forgiven day keeps the streak but does not add to it.** The streak is
  the number of days he studied since the last reset.

And three choices of this module's own, each the kinder or the plainer reading:

- **Today is not missed until it ends.** A student who has not studied yet
  today still sees yesterday's streak - as before #204.
- **Days before his first answer are not missed days.** A student who starts
  on a Thursday has two days off for the rest of that week, not a week that
  already spent them on the days before he began.
- **The allowance is per week, not per streak.** A reset does not refill it:
  every missed day past the second in a week resets the streak again.

"The third missed day" is counted forward, in the order he lived it: two
misses, a studied day, then a third miss resets, and the studied day between
them is lost with the rest.
"""

from collections.abc import Iterable
from datetime import date, datetime, timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from backend.core.clock import app_date
from backend.core.clock import today as app_today
from backend.repositories.student_answer_repository import StudentAnswerRepository

# Missed days a calendar week forgives; the next one resets the streak (#204).
DAYS_OFF_PER_WEEK = 2


def _monday(day: date) -> date:
    """The Monday that starts `day`'s calendar week - the week's key."""
    return day - timedelta(days=day.weekday())


def current_streak(answered_at: Iterable[datetime], today: date) -> int:
    """The streak on `today`, given the moments he answered something.

    Walked forward from his first studied day, so each week's misses are
    counted in the order he missed them. Today adds only once studied.
    """
    studied = {app_date(moment) for moment in answered_at}
    if not studied:
        return 0
    streak = 0
    misses: dict[date, int] = {}
    day = min(studied)
    while day < today:
        if day in studied:
            streak += 1
        else:
            week = _monday(day)
            misses[week] = misses.get(week, 0) + 1
            if misses[week] > DAYS_OFF_PER_WEEK:
                streak = 0
        day += timedelta(days=1)
    return streak + (today in studied)


async def student_streak(db: AsyncSession, student_id) -> int:
    """The signed-in student's streak as of today (the app's calendar date)."""
    answered_at = await StudentAnswerRepository(db).list_answered_at_by_student(student_id)
    return current_streak(answered_at, app_today())
