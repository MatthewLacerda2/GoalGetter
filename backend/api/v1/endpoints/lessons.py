"""Lessons: serve a cut of the goal's question bank, then grade what comes back.

Mounted at `/goals` next to `goals.router`. The bank is built by the student
chain (services/jobs/student_chain.py), never at request time: an empty bank is
a 409.

**A lesson is not a row** (#131). Serving writes nothing, so there is no lesson
to submit *to*: the answers arrive as one batch, and the backend marks them
with a `lesson_id` of its own as it saves them.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from backend.api.v1.goal_dependencies import get_owned_goal
from backend.core.database import get_db
from backend.models.goal import Goal
from backend.repositories.goal_repository import GoalRepository
from backend.repositories.question_repository import QuestionRepository
from backend.repositories.student_answer_repository import StudentAnswerRepository
from backend.schemas.lesson import (
    LessonAnswersRequest,
    LessonEvaluation,
    LessonQuestionResponse,
    LessonResponse,
)
from backend.services.lessons.grading import UnknownQuestionError, grade_lesson
from backend.services.lessons.rasch import replay
from backend.services.lessons.selection import select_lesson_questions

router = APIRouter()

LESSONS_NOT_READY = "Lessons are still being prepared"


@router.post(
    "/{goal_id}/lessons", response_model=LessonResponse, status_code=status.HTTP_201_CREATED
)
async def start_lesson(goal: Goal = Depends(get_owned_goal), db: AsyncSession = Depends(get_db)):
    """Open a lesson: the questions the selection picks (see select_lesson_questions).

    How many that is belongs to the selection, not here: a lesson is two
    minutes, not a constant this endpoint knows.
    """
    bank = await QuestionRepository(db).list_bank_history(goal.id)
    questions = select_lesson_questions(bank)
    if not questions:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=LESSONS_NOT_READY)

    return LessonResponse(
        questions=[
            LessonQuestionResponse(
                id=str(question.id),
                question=question.text,
                choices=[
                    question.option_a,
                    question.option_b,
                    question.option_c,
                    question.option_d,
                ],
                correct_answer_index=question.right_answer_index,
            )
            for question in questions
        ]
    )


@router.post("/{goal_id}/lessons/answers", response_model=LessonEvaluation)
async def submit_lesson_answers(
    payload: LessonAnswersRequest,
    goal: Goal = Depends(get_owned_goal),
    db: AsyncSession = Depends(get_db),
):
    """Grade the batch server-side, store it under one fresh `lesson_id`, move the rating.

    An answer naming a question outside this goal's bank, or naming one twice,
    is a 422 and stores nothing.

    The rating is **replayed**, not nudged (#62): the answers are written first,
    and then the whole history - this lesson included - is walked to the number
    the student is worth now. `elo` is what that costs him or pays him, the
    difference against the rating the goal was carrying.
    """
    bank = await QuestionRepository(db).list_by_goal(goal.id)
    try:
        graded = grade_lesson(bank, payload.answers)
    except UnknownQuestionError as err:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(err)
        ) from err
    answers = StudentAnswerRepository(db)
    await answers.create_many(graded.answers)

    ratings = replay(bank, await answers.list_history_by_goal(goal.id))
    delta = ratings.rating - goal.rating
    await GoalRepository(db).set_rating(goal.id, ratings.rating)
    await db.commit()
    return LessonEvaluation(
        total_seconds_spent=graded.total_seconds, student_accuracy=graded.accuracy, elo=delta
    )
