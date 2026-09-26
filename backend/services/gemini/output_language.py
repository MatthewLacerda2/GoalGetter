"""The language a prompt tells Gemini to write in (#173).

Every prompt names its output language outright, by hand, in its own words
(`CLAUDE.md`): "write in the same language the user used" guessed, and the
nightly jobs have no message of his to guess from. This module only answers
*which* language that line names; writing the line is each prompt's job.

**Where it comes from.** `students.language`, the language he chose in the app
(#172), or on the public onboarding endpoints the `X-Student-Language` header
that stores it. When neither says anything - a student who has not opened the
app since #172, or a client that sent no header - the fallback is what he
typed (his goal, his message), read by `detect_language`, and then English.

Detection is used here and nowhere else because the stakes differ: storing a
guess as his language would outlive the request, while writing one reply in the
language of the words he just wrote is exactly what the old prompts did, only
decided in code instead of by the model. English last because a language
nothing points to is a guess either way, and English is the one the prompts
themselves are written in.
"""

from backend.core.language import Language
from backend.services.language.detection import detect_language

# The name a prompt writes. In English, like the prompts themselves.
LANGUAGE_NAMES: dict[Language, str] = {
    Language.ENGLISH: "English",
    Language.PORTUGUESE: "Portuguese",
    Language.SPANISH: "Spanish",
    Language.FRENCH: "French",
    Language.GERMAN: "German",
}


def output_language(chosen: str | None, *typed: str) -> Language:
    """His chosen language; else the language of what he typed; else English."""
    if chosen:
        try:
            return Language(chosen)
        except ValueError:
            pass
    return detect_language(" ".join(typed)) or Language.ENGLISH


def language_name(language: Language) -> str:
    return LANGUAGE_NAMES[language]
