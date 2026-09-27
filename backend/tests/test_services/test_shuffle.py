"""The right option's position is a draw, not Gemini's choice (2026-09-26)."""

import random
import uuid
from collections import Counter

from backend.services.lessons.shuffle import shuffled_question

TEXT = "Capital of Japan?"
OPTIONS = ["Osaka", "Tokyo", "Kyoto", "Nagoya"]
GOAL = uuid.UUID(int=1)


def options(question) -> list[str]:
    return [question.option_a, question.option_b, question.option_c, question.option_d]


def test_the_right_answer_follows_its_option_wherever_it_lands():
    rng = random.Random(7)
    for _ in range(50):
        question = shuffled_question(GOAL, TEXT, OPTIONS, 1, rng)

        assert options(question)[question.right_answer_index] == "Tokyo"
        assert sorted(options(question)) == ["Kyoto", "Nagoya", "Osaka", "Tokyo"]


def test_every_position_is_used():
    """Gemini put it on B six times in eight; a draw spreads it over all four"""
    rng = random.Random(7)
    landed = Counter(
        shuffled_question(GOAL, TEXT, OPTIONS, 1, rng).right_answer_index for _ in range(400)
    )

    assert set(landed) == {0, 1, 2, 3}
    assert min(landed.values()) > 60
