"""Where the right option sits is a draw, not Gemini's choice (2026-09-26).

Left to the model, the right answer landed on B six times in eight and never on
A or D - a student learns the position before the subject, and his rating then
measures that. Arithmetic decides what appears (CLAUDE.md), so the order is
shuffled here, once, before the question is stored; from then on it is fixed and
every screen shows the same order.
"""

import random

from backend.models.question import Question
from backend.services.gemini.lesson.schema import LessonQuestionItem


def shuffled_question(goal_id, item: LessonQuestionItem, rng: random.Random) -> Question:
    """The stored question for `item`, its four options in a random order and
    `right_answer_index` following the right one to wherever it landed."""
    options = [item.option_a, item.option_b, item.option_c, item.option_d]
    right = options[item.correct_option_index]
    rng.shuffle(options)
    return Question(
        goal_id=goal_id,
        text=item.question,
        option_a=options[0],
        option_b=options[1],
        option_c=options[2],
        option_d=options[3],
        right_answer_index=options.index(right),
    )
