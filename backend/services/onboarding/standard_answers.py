"""The keys the app answers the standard questions with, turned into what the
database stores (#132).

The resolving lives here and not in `repositories/onboarding_repository.py`
because a repository reaching up into services is the wrong way round (#211).
The repository is handed `StandardAnswer`s - the sentences and the index - and
never learns that keys exist.
"""

import logging
from collections.abc import Sequence

from backend.repositories.onboarding_repository import StandardAnswer
from backend.services.onboarding.standard_questions import STANDARD_QUESTIONS

logger = logging.getLogger(__name__)


def resolve_standard_answers(
    answers: Sequence[tuple[str, str, int | None]],
) -> list[StandardAnswer]:
    """The rows to store for `(question key, option key, seconds)` answers.

    A key neither side knows is dropped and logged rather than refused: the
    client can only have sent one this backend served, so an unknown key is a
    build older than the question list - and losing one fact about the student
    is never worth costing him the lesson he is on his way to.
    """
    resolved = []
    for question_key, option_key, seconds in answers:
        answer = _resolve(question_key, option_key, seconds)
        if answer is None:
            logger.info("Standard onboarding: unknown key %s/%s", question_key, option_key)
            continue
        resolved.append(answer)
    return resolved


def _resolve(question_key: str, option_key: str, seconds: int | None) -> StandardAnswer | None:
    """The standard question a key names, with the index of the option picked."""
    for question in STANDARD_QUESTIONS:
        if question.key != question_key:
            continue
        first, second, third, fourth = question.options
        texts = (first.text, second.text, third.text, fourth.text)
        for index, option in enumerate(question.options):
            if option.key == option_key:
                return StandardAnswer(question.text, texts, index, seconds)
    return None
