"""Step 2: the question bank, one goal at a time.

It reads the student's still-valid contexts (written by step 1 a moment ago, or
standing from an earlier run), the goal's current frontier - what the app is
teaching him now, which step 1 may have moved a moment ago (#133) - and the
goal's bank with every question's latest answer.

**It generates when tomorrow's lesson would be too easy, not when the bank is
small (#135).** The step builds tomorrow's lesson exactly as the endpoint would,
with the same selection and the same pace, and then asks the arithmetic in
`services/lessons/generation.py` whether those questions are still hard enough
for him. A student who keeps missing his questions gets nothing: his bank
already holds what he needs, and the tokens would buy him nothing.

Nothing here counts rows. The inventory rule this replaces (#91) topped the bank
up to two lessons, and how full a bank is says nothing at all about whether the
student still has something to learn from it.
"""

import logging

from backend.models.question import Question
from backend.repositories.frontier_repository import FrontierRepository
from backend.repositories.goal_repository import GoalRepository
from backend.repositories.question_repository import QuestionHistory, QuestionRepository
from backend.repositories.student_answer_repository import StudentAnswerRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.gemini.lesson import generate_lesson_questions
from backend.services.gemini.lesson.schema import AnsweredQuestion
from backend.services.gemini.student_context import GeminiStudentContext
from backend.services.jobs.steps.language import student_language
from backend.services.lessons.generation import decide
from backend.services.lessons.pacing import PACE_WINDOW, lesson_size
from backend.services.lessons.selection import select_lesson
from backend.utils.gemini.gemini_guard import run_gemini_background

logger = logging.getLogger(__name__)

# How many answered questions of each kind - right and wrong - the prompt
# carries. Twenty in all, and they are what the generation is written from: real
# material, never a summary of it (#135).
#
# Ten a side because that is about two lessons' worth of each: enough for the
# model to see a pattern in what he misses rather than one accident, and few
# enough that the questions stay the bulk of a prompt that also holds the
# contexts, the frontier and the guidelines. The rest of the bank is not
# forgotten - it is what the selection keeps serving him.
ANSWERED_SHOWN = 10


async def run_questions_step(session, student_id) -> int:
    """Top up the bank of each of the student's goals. Returns how many
    questions were stored across all of them - zero is the common answer.

    Each goal commits on its own: a goal whose generation fails does not
    discard the banks written for the goals before it.
    """
    goals = await GoalRepository(session).list_by_student(student_id)
    readings = await StudentContextRepository(session).list_valid(student_id)
    contexts = [
        GeminiStudentContext(state=row.state, metacognition=row.metacognition) for row in readings
    ]
    # His pace, and so the size of tomorrow's lesson, is a fact about the person
    # and not about a goal (#134) - read once, used for every bank below.
    seconds = await StudentAnswerRepository(session).list_recent_seconds(student_id, PACE_WINDOW)
    language = await student_language(session, student_id, goals)

    total = 0
    for goal in goals:
        total += await _bank_for_goal(
            session, goal, contexts, readings, lesson_size(seconds), language
        )
    return total


async def _bank_for_goal(session, goal, contexts, readings, size: int, language) -> int:
    repository = QuestionRepository(session)
    bank = await repository.list_bank_history(goal.id)
    frontier = await FrontierRepository(session).current(goal.id)
    lesson = select_lesson(
        bank=[entry.question for entry in bank],
        history=await StudentAnswerRepository(session).list_history_by_goal(goal.id),
        size=size,
        frontier=frontier,
        context=readings[0] if readings else None,
    )

    verdict = decide(lesson, goal.rating)
    logger.info(
        "Questions step: student %s, goal %s - %s", goal.student_id, goal.id, verdict.reason
    )
    if not verdict.generate:
        return 0

    generated = await run_gemini_background(
        generate_lesson_questions,
        goal.name,
        goal.description,
        frontier.definition if frontier else (goal.description or ""),
        goal.rating,
        verdict.target,
        contexts,
        _answered(bank, right=True),
        _answered(bank, right=False),
        language,
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


def _answered(bank: list[QuestionHistory], right: bool) -> list[AnsweredQuestion]:
    """The questions whose *latest* answer was right (or wrong), newest first.

    The latest answer and not every one: a question he has since got right is no
    longer a weakness, and one he has since got wrong is no longer settled. It
    is the same reading of the bank the selection orders on.
    """
    seen = [entry for entry in bank if entry.last_was_correct is right]
    seen.sort(key=lambda entry: entry.last_answered_at, reverse=True)
    return [_shown(entry) for entry in seen[:ANSWERED_SHOWN]]


def _shown(entry: QuestionHistory) -> AnsweredQuestion:
    """One answered question with the option he picked and the one that was
    right, both as the text he read rather than as an index."""
    question = entry.question
    options = [question.option_a, question.option_b, question.option_c, question.option_d]
    return AnsweredQuestion(
        question=question.text,
        chosen=options[entry.last_selected_index],
        correct=options[question.right_answer_index],
    )
