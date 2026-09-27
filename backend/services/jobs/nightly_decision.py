"""Who the nightly run serves tonight, and why (#89).

**The rules, in the user's terms (2026-09-23).** The most important thing is
that the student has lessons to do every day. Generation runs at night, when
Google's servers are quiet and nobody is studying - by then the student either
did today's lesson or was not going to. A student who did no lesson that day is
skipped *entirely*: no context, no questions, no call at all. A day counts
because he answered at least one question in it - there is no lesson
row. Chat activity does not count; only answers do. Resources are rare - Monday only, and only for
a student who studied in the past week.

**"That day" is not the calendar day.** The run fires at 03:00, and reading the
calendar date there would skip everyone who studied the evening before, which
is everyone. The day the run closes out is the 24 hours behind it - see
`clock.previous_nightly_run`.

Arithmetic, and kept apart from `nightly.py` for that reason: the rule decides
whether Gemini is called at all, so this module must never reach it, not even
through the chain `nightly.py` runs (the import contracts in
backend/pyproject.toml).
"""

from dataclasses import dataclass
from datetime import datetime

from backend.core import clock

# Monday, as `datetime.weekday()` numbers the days.
RESOURCE_WEEKDAY = 0


@dataclass(frozen=True)
class Decision:
    """What the run decided about one student, and the sentence that says why.

    The reason is not decoration: running the job by hand for one student is
    how its behaviour is watched, and what there is to watch is exactly
    these sentences.
    """

    run: bool
    with_resources: bool
    reason: str


def decide(last_answer: datetime | None, at: datetime) -> Decision:
    """Everything the nightly run decides about one student, from one moment.

    Pure on purpose: the gate is a rule about days and weekdays, and a rule
    like that is worth pinning in a test that needs neither a database nor a
    scheduler to state it.
    """
    since = clock.previous_nightly_run(at)
    if last_answer is None:
        return Decision(False, False, "skipped: no question has ever been answered")

    last = clock.as_utc(last_answer)
    if last < since:
        return Decision(
            False, False, f"skipped: last answer {last:%Y-%m-%d %H:%M}Z is before {since:%H:%M}Z"
        )
    if clock.app_local(at).weekday() != RESOURCE_WEEKDAY:
        return Decision(True, False, "context and questions: a question was answered today")

    # The rule also says resources need study in the last seven days, and
    # there is no test of it here because reaching this line already proves it:
    # the student studied within the last 24 hours or they were skipped above.
    # Writing the week out as a second comparison would be a branch no input
    # can take - a rule stated twice, enforced once.
    return Decision(True, True, "context, questions and resources: Monday with a lesson this week")
