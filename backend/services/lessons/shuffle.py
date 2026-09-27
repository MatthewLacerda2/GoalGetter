"""Where the right option sits is a draw, not Gemini's choice (2026-09-26).

Left to the model, the right answer landed on B six times in eight and never on
A or D - a student learns the position before the subject, and his rating then
measures that. Arithmetic decides what appears (CLAUDE.md), so the order is
shuffled here, once, before the question is stored; from then on it is fixed and
every screen shows the same order.

It takes the question as plain values, not as Gemini's `LessonQuestionItem`:
this is arithmetic, and arithmetic never imports the Gemini layer (#211, the
import contracts in backend/pyproject.toml).
"""

import random

from backend.models.question import Question


def shuffled_question(
    goal_id, text: str, options: list[str], right_index: int, rng: random.Random
) -> Question:
    """The stored question: its four `options` in a random order, and
    `right_answer_index` following the one at `right_index` to wherever it landed."""
    options = list(options)
    right = options[right_index]
    rng.shuffle(options)
    return Question(
        goal_id=goal_id,
        text=text,
        option_a=options[0],
        option_b=options[1],
        option_c=options[2],
        option_d=options[3],
        right_answer_index=options.index(right),
    )
