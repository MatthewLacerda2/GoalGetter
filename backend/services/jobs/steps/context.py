"""Step 1: the app's reading of the learner.

What it reads is decided by what it finds, never by a flag:

* nothing to revise - no lesson the student has answered, or no context left
  standing - and it writes the **first impression**, from the onboarding rows
  goal creation stored and from every goal the student has;
* otherwise it **revises** the newest context from the student's recent lesson
  answers and tutor chats, across every goal.

Both generators already existed; until now only the first one was ever called
(backend_contract.md, Background jobs). The context is committed on its own: it
is worth keeping even if the steps after it fail.
"""

import logging

from backend.models.student_context import StudentContext
from backend.repositories.chat_message_repository import ChatMessageRepository
from backend.repositories.goal_repository import GoalRepository
from backend.repositories.lesson_answer_repository import LessonAnswerRepository
from backend.repositories.onboarding_repository import OnboardingRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.gemini.student_context import (
    StudentGoal,
    gemini_generate_periodic_student_context,
    gemini_generate_student_context,
)
from backend.utils.gemini.gemini_guard import run_gemini_background

logger = logging.getLogger(__name__)

# How much history a revision reads. Enough to see a trend, small enough that
# the prompt stays about the student rather than about a transcript.
RECENT_ANSWERS = 30
RECENT_CHATS = 10


async def run_context_step(session, student_id) -> bool:
    """Write one student context. Returns whether one was written.

    A student with no goals has nothing to be written about, which is the one
    case where the step spends nothing and returns False.
    """
    goals = await GoalRepository(session).list_by_student(student_id)
    if not goals:
        logger.info("Context step: student %s has no goals, nothing to write", student_id)
        return False

    prompt_goals = [StudentGoal(name=goal.name, description=goal.description) for goal in goals]
    answers = await LessonAnswerRepository(session).list_recent_by_student(
        student_id, RECENT_ANSWERS
    )
    contexts = await StudentContextRepository(session).list_valid(student_id)

    if answers and contexts:
        generated = await _revision(session, student_id, prompt_goals, contexts[0], answers)
    else:
        generated = await _first_impression(session, student_id, prompt_goals)

    await StudentContextRepository(session).create(
        StudentContext(
            student_id=student_id,
            state=generated.state,
            metacognition=generated.metacognition,
        )
    )
    await session.commit()
    return True


async def _first_impression(session, student_id, goals: list[StudentGoal]):
    """The reading of someone we have watched do nothing yet: their own words
    and the questions they answered while creating their goals.

    The onboarding is read from the database, not received as an argument, so
    this runs the same whether goal creation fired it a second ago or the
    nightly run picked it up after that attempt failed (#88).
    """
    rows = await OnboardingRepository(session).list_by_student(student_id)
    # Every row is a question and what the student gave for it - including the
    # free-text one, whose question is what the start screen asked them.
    questions_answers = [(row.question, row.option_a) for row in rows]
    logger.info(
        "Context step: first impression for student %s from %d onboarding answers",
        student_id,
        len(questions_answers),
    )
    return await run_gemini_background(
        gemini_generate_student_context, goals, None, questions_answers
    )


async def _revision(session, student_id, goals: list[StudentGoal], previous, answers):
    """The reading of someone we have now watched study: the newest context,
    revised against what they have been getting right, wrong and asking about."""
    chats = await ChatMessageRepository(session).list_recent_by_student(student_id, RECENT_CHATS)
    logger.info(
        "Context step: revising student %s from %d answers and %d chats",
        student_id,
        len(answers),
        len(chats),
    )
    return await run_gemini_background(
        gemini_generate_periodic_student_context,
        goals,
        previous.state,
        previous.metacognition,
        [_answer_seen(answer, question) for answer, question in answers],
        [
            {"prompt": chat.prompt, "tutor_response": " ".join(chat.tutor_responses)}
            for chat in chats
        ],
    )


def _answer_seen(answer, question) -> dict:
    """One answer as the periodic prompt reads it: the question, the option the
    student picked (its text, not its index), and how long they took."""
    options = [question.option_a, question.option_b, question.option_c, question.option_d]
    index = answer.selected_option_index
    return {
        "question": question.question,
        "selected_option": options[index] if 0 <= index < len(options) else "",
        "is_correct": answer.is_correct,
        "time_spent": answer.time_spent,
    }
