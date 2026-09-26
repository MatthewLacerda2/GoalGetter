"""`detect_language(text)`: which of the app's languages a text is written in.

Deterministic and cheap, on purpose (#172): split the text into words, count
how many of them are among each language's commonest short words
(`common_words.py`), and the language with the most wins. No model call.

**It answers None when it cannot tell** — no common word at all ("Chess",
"Python", a name), or two languages tied at the top. A silent default would be
a guess dressed as an answer, and every caller would inherit it.

It does not decide the student's language: he chooses that
(`core/language.py`). It is a tool for texts - e.g. noticing that a student
whose app is in English just wrote his goal in Portuguese.
"""

import re

from backend.core.language import Language
from backend.services.language.common_words import COMMON_WORDS

# Runs of letters, accents included. An apostrophe splits, so French "j'aime"
# gives "j" and "aime", and "j" is a French word in its own right.
_WORD = re.compile(r"[^\W\d_]+")


def detect_language(text: str) -> Language | None:
    words = _WORD.findall(text.lower())
    scores = {
        language: sum(word in common for word in words) for language, common in COMMON_WORDS.items()
    }
    ranked = sorted(scores.values(), reverse=True)
    if ranked[0] == 0 or ranked[0] == ranked[1]:
        return None
    return max(scores, key=scores.get)
