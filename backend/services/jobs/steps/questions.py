"""Step 2: the question bank, one goal at a time.

It reads the student's still-valid contexts (written by step 1 a moment ago, or
standing from an earlier run), the goal itself, and the questions of that goal
the student most recently got wrong. An empty list of errors is the normal case
for a student who has answered nothing, not a special one.

**How many questions to generate is not decided here.** Today every goal gets a
generation; #91 is the issue that makes it look at what tomorrow could already
be built from and generate nothing when the bank is deep enough.
"""

import logging

from backend.models.lesson_question import LessonQuestion
from backend.repositories.goal_repository import GoalRepository
from backend.repositories.lesson_question_repository import LessonQuestionRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.gemini.lesson import generate_lesson_questions
from backend.services.gemini.student_context import GeminiStudentContext
from backend.utils.gemini.gemini_guard import run_gemini_background

logger = logging.getLogger(__name__)

# How many of the student's recent mistakes the prompt is shown. The bank is
# what repeats a question until it is answered right (#55); this only aims the
# *new* questions at where they keep slipping.
RECENT_ERRORS = 10


async def run_questions_step(session, student_id) -> int:
    """Generate a bank for each of the student's goals. Returns how many
    questions were stored across all of them.

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
    repository = LessonQuestionRepository(session)
    generated = await run_gemini_background(
        generate_lesson_questions,
        goal.name,
        goal.description,
        goal.rating,
        contexts,
        await _recent_errors(repository, goal.id),
    )
    # A question whose correct index is out of range would fail the table's
    # check constraint and take the whole batch with it: drop just that one.
    questions = [
        LessonQuestion(
            goal_id=goal.id,
            question=item.question,
            option_a=item.option_a,
            option_b=item.option_b,
            option_c=item.option_c,
            option_d=item.option_d,
            correct_option_index=item.correct_option_index,
        )
        for item in generated.questions
        if 0 <= item.correct_option_index <= 3
    ]
    await repository.create_many(questions)
    await session.commit()
    logger.info("Questions step: stored %d questions for goal %s", len(questions), goal.id)
    return len(questions)


async def _recent_errors(repository: LessonQuestionRepository, goal_id) -> list[str]:
    """The questions of this goal whose *latest* answer was wrong, newest first.

    Same reading of the bank that lesson selection uses: a question the student
    has since got right is no longer a weakness.
    """
    wrong = [
        history
        for history in await repository.list_bank_history(goal_id)
        if history.last_was_correct is False
    ]
    wrong.sort(key=lambda history: history.last_answered_at, reverse=True)
    return [history.question.question for history in wrong[:RECENT_ERRORS]]
