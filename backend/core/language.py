"""The languages the app speaks, and how a request says which one is his.

Five, the same five the Flutter app has ARB files for
(`frontend/lib/l10n/app_*.arb`). The value is the two-letter code both sides
already use, so the app's stored preference is the enum's value as is.

**The student chooses his language; nothing guesses it** (#172). The app sends
the choice on every request in the `X-Student-Language` header — from the start
screen's selector, defaulting to the phone's language, and from the profile —
and the backend mirrors it onto `students.language` whenever it differs
(`core/security.py`). That one mechanism is also how a student who signed up
before the column existed gets one: his next request fills it. Until then the
column is null, which honestly means "not told yet".

`services/language/detection.py` classifies a text, but never decides the
student's language: a goal of "Chess" or "Python" says nothing about what he
speaks.
"""

from enum import StrEnum

from fastapi import Header


class Language(StrEnum):
    ENGLISH = "en"
    PORTUGUESE = "pt"
    SPANISH = "es"
    FRENCH = "fr"
    GERMAN = "de"


def requested_language(
    x_student_language: str | None = Header(
        None, description="The student's chosen language: en, pt, es, fr or de"
    ),
) -> Language | None:
    """The language the request says the student chose, or None when it says
    nothing usable. An unknown code is ignored rather than refused: a stale app
    must not lose every request over a preference."""
    if x_student_language is None:
        return None
    try:
        return Language(x_student_language.strip().lower())
    except ValueError:
        return None
