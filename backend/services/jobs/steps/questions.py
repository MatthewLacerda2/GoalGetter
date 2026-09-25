"""Step 2: the question bank, one goal at a time.

It reads the student's still-valid contexts (written by step 1 a moment ago, or
standing from an earlier run), the goal itself, and the questions of that goal
the student most recently got wrong. An empty list of errors is the normal case
for a student who has answered nothing, not a special one.

**It generates only when tomorrow would run short (#91).** A lesson is filled
from the questions the student got wrong last time and the ones they have never
seen (`services/lessons/selection.py`, #55), so a bank deep in either of those
already has tomorrow covered. That is precisely the student who is struggling,
and the user's rule is that struggling makes our job cheaper, not dearer: a
question stays in rotation until it is answered right, so we do not buy new
ones to sit behind it.
"""

import logging

from backend.models.question import Question
from backend.repositories.goal_repository import GoalRepository
from backend.repositories.question_repository import QuestionRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.gemini.lesson import generate_lesson_questions
from backend.services.gemini.student_context import GeminiStudentContext
from backend.utils.envs import QUESTIONS_PER_LESSON
from backend.utils.gemini.gemini_guard import run_gemini_background

logger = logging.getLogger(__name__)

# How many of the student's recent mistakes the prompt is shown. The bank is
# what repeats a question until it is answered right (#55); this only aims the
# *new* questions at where they keep slipping.
RECENT_ERRORS = 10

# What a generation tops the servable bank up to: two lessons.
#
# One lesson is tomorrow's, and it is the gap we are actually filling. The
# second is the margin, and it is one lesson because a student who answers
# tomorrow's questions correctly consumes all of them - so without it the bank
# is short again the very next night, and the next night is the one that may
# find Gemini down or the quota spent. One lesson of margin buys exactly one
# missed night, which is the failure we can actually expect.
TARGET_SERVABLE = 2 * QUESTIONS_PER_LESSON


async def run_questions_step(session, student_id) -> int:
    """Top up the bank of each of the student's goals. Returns how many
    questions were stored across all of them - zero is the common answer.

    Each goal commits on its own: a goal whose generation fails does not
    discard the banks written for the goals before it.
    """
    goals = await GoalRepository(session).list_by_student(student_id)
    contexts = [
        GeminiStudentContext(state=row.state, metacognition=row.metacognition)
        for row in await StudentContextRepository(session).list_valid(student_id)
    ]

    total = 0
    for goal in goals:
        total += await _bank_for_goal(session, goal, contexts)
    return total


async def _bank_for_goal(session, goal, contexts: list[GeminiStudentContext]) -> int:
    repository = QuestionRepository(session)
    history = await repository.list_bank_history(goal.id)
    servable = [h for h in history if h.last_was_correct is False or h.last_answered_at is None]

    if len(servable) >= QUESTIONS_PER_LESSON:
        logger.info(
            "Questions step: goal %s has %d servable questions, tomorrow is covered",
            goal.id,
            len(servable),
        )
        return 0

    wanted = TARGET_SERVABLE - len(servable)
    logger.info(
        "Questions step: goal %s has %d servable questions, asking for %d",
        goal.id,
        len(servable),
        wanted,
    )
    generated = await run_gemini_background(
        generate_lesson_questions,
        goal.name,
        goal.description,
        goal.rating,
        contexts,
        _recent_errors(history),
        wanted,
    )
    # A question whose correct index is out of range would fail the table's
    # check constraint and take the whole batch with it: drop just that one.
    questions = [
        Question(
            goal_id=goal.id,
            text=item.question,
            option_a=item.option_a,
            option_b=item.option_b,
            option_c=item.option_c,
            option_d=item.option_d,
            right_answer_index=item.correct_option_index,
        )
        for item in generated.questions
        if 0 <= item.correct_option_index <= 3
    ]
    await repository.create_many(questions)
    await session.commit()
    logger.info("Questions step: stored %d questions for goal %s", len(questions), goal.id)
    return len(questions)


def _recent_errors(history) -> list[str]:
    """The questions of this goal whose *latest* answer was wrong, newest first.

    Same reading of the bank that lesson selection uses: a question the student
    has since got right is no longer a weakness.
    """
    wrong = [entry for entry in history if entry.last_was_correct is False]
    wrong.sort(key=lambda entry: entry.last_answered_at, reverse=True)
    return [entry.question.text for entry in wrong[:RECENT_ERRORS]]
