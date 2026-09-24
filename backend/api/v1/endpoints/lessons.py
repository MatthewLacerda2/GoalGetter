"""Lessons: serve a lesson from the goal's question bank, then grade its answers.

Mounted at `/goals` next to `goals.router`. The bank is built by the goal jobs
(services/jobs/goal_jobs.py), never at request time: an empty bank is a 409.
"""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from backend.api.v1.goal_dependencies import get_owned_goal
from backend.core import clock
from backend.core.database import get_db
from backend.models.goal import Goal
from backend.models.lesson import Lesson
from backend.repositories.goal_repository import GoalRepository
from backend.repositories.lesson_answer_repository import LessonAnswerRepository
from backend.repositories.lesson_question_repository import LessonQuestionRepository
from backend.repositories.lesson_repository import LessonRepository
from backend.schemas.lesson import (
    LessonAnswersRequest,
    LessonEvaluation,
    LessonQuestionResponse,
    LessonResponse,
)
from backend.services.lessons.elo import lesson_elo_delta
from backend.services.lessons.grading import UnservedQuestionError, grade_lesson
from backend.services.lessons.selection import select_lesson_questions
from backend.utils.envs import QUESTIONS_PER_LESSON

router = APIRouter()

LESSONS_NOT_READY = "Lessons are still being prepared"
LESSON_NOT_FOUND = "Lesson not found"
LESSON_ALREADY_ANSWERED = "Lesson already answered"


@router.post(
    "/{goal_id}/lessons", response_model=LessonResponse, status_code=status.HTTP_201_CREATED
)
async def start_lesson(goal: Goal = Depends(get_owned_goal), db: AsyncSession = Depends(get_db)):
    """Open a lesson: pick its questions from the bank (see select_lesson_questions)."""
    bank = await LessonQuestionRepository(db).list_bank_history(goal.id)
    questions = select_lesson_questions(bank, QUESTIONS_PER_LESSON)
    if not questions:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=LESSONS_NOT_READY)

    lesson = await LessonRepository(db).create(
        Lesson(goal_id=goal.id, question_ids=[q.id for q in questions])
    )
    await db.commit()
    return LessonResponse(
        lesson_id=str(lesson.id),
        questions=[
            LessonQuestionResponse(
                id=str(q.id),
                question=q.question,
                choices=[q.option_a, q.option_b, q.option_c, q.option_d],
                correct_answer_index=q.correct_option_index,
            )
            for q in questions
        ],
    )


@router.post("/{goal_id}/lessons/{lesson_id}/answers", response_model=LessonEvaluation)
async def submit_lesson_answers(
    lesson_id: UUID,
    payload: LessonAnswersRequest,
    goal: Goal = Depends(get_owned_goal),
    db: AsyncSession = Depends(get_db),
):
    """Grade the lesson server-side, store one answer per question, move the goal's rating."""
    lessons = LessonRepository(db)
    lesson = await lessons.get_in_goal_for_update(lesson_id, goal.id)
    if lesson is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=LESSON_NOT_FOUND)
    if lesson.finished_at is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=LESSON_ALREADY_ANSWERED)

    served = await LessonQuestionRepository(db).list_by_ids(lesson.question_ids)
    try:
        graded = grade_lesson(lesson.id, served, payload.answers)
    except UnservedQuestionError as err:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(err)
        ) from err
    await LessonAnswerRepository(db).create_many(graded.answers)

    delta = lesson_elo_delta(goal.rating, graded.accuracy)
    new_rating = await GoalRepository(db).add_to_rating(goal.id, delta)

    lesson.finished_at = clock.now()
    lesson.total_seconds, lesson.accuracy = graded.total_seconds, graded.accuracy
    lesson.elo_delta, lesson.elo_after = delta, new_rating
    await lessons.update(lesson)
    await db.commit()
    return LessonEvaluation(
        total_seconds_spent=graded.total_seconds, student_accuracy=graded.accuracy, elo=delta
    )
