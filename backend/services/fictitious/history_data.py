# lint: data-file
"""The hardcoded history `make claude` gives Fictitious Claude (#60).

Nothing here comes from Gemini or YouTube: it is written by hand to make Home,
Profile, the goals list, the tutor chat and the resources screen look
lived-in. Times are relative to the moment of seeding (`days_ago`, `hour`), so
the streak is real whenever the seeder runs; the hours are the student's wall
clock, `core.clock.APP_TIMEZONE` (#92).

This module is the assembly point - `GOALS` is what the seeder reads. The bulk
of the content lives next to it by subject, each file data like this one
(#107): `history_questions`, `history_chat`, `history_resources`.

Lesson plan: each entry is (days_ago, hour, correct answers out of
LESSON_SIZE). The active goal has lessons on 14 of the last 15 days, two on a
couple of days, and a gap 6 days ago, so the streak is 6 and not 15.
"""

from backend.services.fictitious.history_chat import GUITAR_CHAT, ITALIAN_CHAT, PYTHON_CHAT
from backend.services.fictitious.history_questions import (
    GUITAR_QUESTIONS,
    ITALIAN_QUESTIONS,
    PYTHON_QUESTIONS,
)
from backend.services.fictitious.history_resources import (
    GUITAR_RESOURCES,
    ITALIAN_RESOURCES,
    PYTHON_RESOURCES,
)

LESSON_SIZE = 5
START_RATING = 1200  # the Goal.rating column default

ITALIAN_LESSONS = [
    (14, 20, 2),
    (13, 19, 3),
    (12, 21, 2),
    (11, 8, 3),
    (10, 19, 3),
    (10, 22, 4),
    (9, 20, 3),
    (8, 12, 4),
    (7, 21, 3),
    # the gap: nothing 6 days ago
    (5, 19, 4),
    (4, 20, 3),
    (3, 9, 4),
    (3, 18, 5),
    (2, 21, 4),
    (1, 20, 5),
    (0, None, 4),
]
GUITAR_LESSONS = [(24, 18, 2), (23, 19, 3), (21, 20, 3)]
PYTHON_LESSONS = [(33, 10, 3), (31, 11, 4)]

ITALIAN_CONTEXT = (
    "A beginner preparing for a one-week trip to Rome in three weeks. Solid on greetings and "
    "ordering food; still slips on articles (lo/il) and on essere vs avere in the passato prossimo.",
    "Studies in the evening, one short lesson a day, sometimes two. Asks 'why' questions and "
    "remembers rules better with a mnemonic.",
)

# The goals, newest (and active) first. `created_days_ago` must predate the
# goal's first lesson.
GOALS = [
    {
        "name": "Conversational Italian for a trip to Rome",
        "description": "Get by in Italian on a week in Rome: greetings, ordering food, asking the way, "
        "buying train tickets, and small talk with locals.",
        "created_days_ago": 15,
        "active": True,
        "questions": ITALIAN_QUESTIONS,
        "lessons": ITALIAN_LESSONS,
        "chat": ITALIAN_CHAT,
        "resources": ITALIAN_RESOURCES,
        "context": ITALIAN_CONTEXT,
    },
    {
        "name": "Music theory for guitar",
        "description": "Understand the chords and scales I already play: intervals, keys, and why the "
        "pentatonic works for solos.",
        "created_days_ago": 26,
        "active": False,
        "questions": GUITAR_QUESTIONS,
        "lessons": GUITAR_LESSONS,
        "chat": GUITAR_CHAT,
        "resources": GUITAR_RESOURCES,
        "context": None,
    },
    {
        "name": "Python for data analysis",
        "description": "Clean and explore spreadsheets with pandas instead of doing it by hand in Excel.",
        "created_days_ago": 35,
        "active": False,
        "questions": PYTHON_QUESTIONS,
        "lessons": PYTHON_LESSONS,
        "chat": PYTHON_CHAT,
        "resources": PYTHON_RESOURCES,
        "context": None,
    },
]

# The student's member-since date.
STUDENT_CREATED_DAYS_AGO = 36
