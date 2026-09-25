"""Step 1: the app's reading of the learner.

What it does is decided by what it finds, never by a flag:

* nothing to review - no lesson the student has answered, or no context left
  standing - and it writes the **first impression**, from the onboarding rows
  goal creation stored and from every goal the student has;
* otherwise it asks Gemini to **review** the readings that stand: which of them
  have gone stale, and what is now missing (#90).

**The review is not a rewrite.** Regenerating the whole context every night
paid a premium call to produce much the same paragraphs. So the prompt carries
the standing readings numbered, and the answer points at them: an empty answer
is a valid, normal and cheap outcome meaning nothing changed.

**A stale reading is retired, never deleted** (`is_still_valid = False`): it is
progression history the student is meant to be able to read.

The step commits on its own: what it wrote is worth keeping even if the steps
after it fail.
"""

import logging

from backend.models.student_context import StudentContext
from backend.repositories.chat_message_repository import ChatMessageRepository
from backend.repositories.goal_repository import GoalRepository
from backend.repositories.onboarding_repository import OnboardingRepository
from backend.repositories.student_answer_repository import StudentAnswerRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.gemini.student_context import (
    GeminiStudentContext,
    StudentGoal,
    gemini_generate_student_context,
    gemini_review_student_context,
)
from backend.utils.gemini.gemini_guard import run_gemini_background

logger = logging.getLogger(__name__)

# How much history a review reads. Enough to see a trend, small enough that
# the prompt stays about the student rather than about a transcript.
RECENT_ANSWERS = 30
RECENT_CHATS = 10


async def run_context_step(session, student_id) -> bool:
    """Bring the student's readings up to date. Returns whether anything moved.

    False is a normal outcome, and there are two of them: a student with no
    goals, who has nothing to be written about and costs nothing; and a review
    that found nothing stale and nothing to add, which is what #90 is for.
    """
    goals = await GoalRepository(session).list_by_student(student_id)
    if not goals:
        logger.info("Context step: student %s has no goals, nothing to write", student_id)
        return False

    prompt_goals = [StudentGoal(name=goal.name, description=goal.description) for goal in goals]
    answers = await StudentAnswerRepository(session).list_recent_by_student(
        student_id, RECENT_ANSWERS
    )
    contexts = await StudentContextRepository(session).list_valid(student_id)

    if answers and contexts:
        return await _review(session, student_id, prompt_goals, contexts, answers)
    return await _first_impression(session, student_id, prompt_goals)


async def _first_impression(session, student_id, goals: list[StudentGoal]) -> bool:
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
    generated = await run_gemini_background(
        gemini_generate_student_context, goals, None, questions_answers
    )
    await _store(session, student_id, [generated])
    await session.commit()
    return True


async def _review(session, student_id, goals: list[StudentGoal], standing, answers) -> bool:
    """Show the model what the app believes and let it say what no longer holds.

    The chats are in the prompt even though the nightly run does not count them
    as activity (#89): what a student asks the tutor is evidence about them,
    and only the *gate* is lessons-only.
    """
    chats = await ChatMessageRepository(session).list_recent_by_student(student_id, RECENT_CHATS)
    logger.info(
        "Context step: reviewing %d standing contexts for student %s from %d answers and %d chats",
        len(standing),
        student_id,
        len(answers),
        len(chats),
    )
    review = await run_gemini_background(
        gemini_review_student_context,
        goals,
        [GeminiStudentContext(state=c.state, metacognition=c.metacognition) for c in standing],
        [_answer_seen(answer, question) for answer, question in answers],
        [
            {"prompt": chat.prompt, "tutor_response": " ".join(chat.tutor_responses)}
            for chat in chats
        ],
    )

    retired = await _retire(session, standing, review.reviewed)
    await _store(session, student_id, review.new_contexts)
    await session.commit()
    logger.info(
        "Context step: student %s - %d retired, %d added",
        student_id,
        retired,
        len(review.new_contexts),
    )
    return bool(retired or review.new_contexts)


async def _retire(session, standing, verdicts) -> int:
    """Mark the readings the model called outdated, and return how many.

    An index it invented, or repeated, is dropped rather than failing the run:
    the first verdict for an index is the one that counts, and an index outside
    what was shown is a hallucination we log and ignore. The question bank
    already tolerates a bad shape the same way.
    """
    repository = StudentContextRepository(session)
    seen: set[int] = set()
    retired = 0
    for verdict in verdicts:
        if not 0 <= verdict.index < len(standing) or verdict.index in seen:
            logger.info("Context step: ignoring verdict on index %s", verdict.index)
            continue
        seen.add(verdict.index)
        if not verdict.is_outdated:
            continue
        context = standing[verdict.index]
        context.is_still_valid = False
        await repository.update(context)
        retired += 1
    return retired


async def _store(session, student_id, generated) -> None:
    """Add the new readings. Never an update: a context row is never rewritten,
    only added beside the ones before it or retired."""
    repository = StudentContextRepository(session)
    for item in generated:
        await repository.create(
            StudentContext(
                student_id=student_id,
                state=item.state,
                metacognition=item.metacognition,
            )
        )


def _answer_seen(answer, question) -> dict:
    """One answer as the prompt reads it: the question, the option the student
    picked (its text, not its index), and how long they took.

    Correctness is worked out here rather than read: `student_answers` stores
    no `is_correct` (#131).
    """
    options = [question.option_a, question.option_b, question.option_c, question.option_d]
    index = answer.selected_index
    return {
        "question": question.text,
        "selected_option": options[index] if 0 <= index < len(options) else "",
        "is_correct": index == question.right_answer_index,
        "time_spent": answer.total_seconds,
    }
