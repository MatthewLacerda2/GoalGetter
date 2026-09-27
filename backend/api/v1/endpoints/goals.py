from typing import Annotated

from fastapi import APIRouter, Depends, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from backend.api.v1.goal_dependencies import get_owned_goal
from backend.api.v1.student_dependencies import get_current_user
from backend.core import clock
from backend.core.database import get_db
from backend.core.errors.api_error import ApiError
from backend.core.errors.codes import ErrorCode
from backend.core.language import Language, requested_language
from backend.core.rate_limiter import limiter
from backend.models.goal import Goal
from backend.models.student import Student
from backend.repositories.goal_repository import GoalRepository
from backend.repositories.onboarding_repository import OnboardingRepository
from backend.repositories.student_repository import StudentRepository
from backend.schemas.goal import (
    GoalCommitRequest,
    GoalCreationRequest,
    GoalCreationResponse,
    GoalResponse,
    ObjectiveQuestion,
    ObjectiveQuestionsRequest,
    SetActiveGoalResponse,
    StandardAnswersRequest,
    StandardQuestionData,
    StudyPlanResponse,
)
from backend.services.gemini.client.gemini_guard import run_gemini
from backend.services.gemini.onboarding.goal_validation import (
    get_prompt_validation,
    is_goal_validated,
)
from backend.services.gemini.onboarding.onboarding import generate_onboarding_questions
from backend.services.gemini.onboarding.study_plan import generate_study_plan
from backend.services.gemini.output_language import output_language
from backend.services.jobs.student_chain import kickoff_student_chain
from backend.services.onboarding.standard_answers import resolve_standard_answers
from backend.services.onboarding.standard_questions import STANDARD_QUESTIONS

router = APIRouter()

# Goal-creation (onboarding) endpoints are intentionally PUBLIC so anyone can try
# the app without signing up. Each one calls Gemini, so it's rate-limited to
# 20/minute per client address to bound AI cost (the global default is 10/second).
# Counted per uvicorn worker, so the real ceiling is 20 to 80 a minute - see
# backend/core/rate_limiter.py for who "a client" is and why.


@router.post("/objective-questions", response_model=list[ObjectiveQuestion])
@limiter.limit("20/minute")
async def objective_questions(
    request: Request,
    payload: ObjectiveQuestionsRequest,
    chosen: Annotated[Language | None, Depends(requested_language)],
):
    """
    Step 1: validate the prompt is a real goal, then generate clarifying
    multiple-choice questions. Each question names the model that wrote it, and
    the app sends that back with its answer to `POST /goals` (#216).

    Public, so there is no student row: the language is the header the app
    sends (#172), else the one the prompt is written in (#173).
    """
    language = output_language(chosen, payload.prompt)
    validation = await run_gemini(get_prompt_validation, payload.prompt, language)
    if not is_goal_validated(validation):
        raise ApiError(ErrorCode.NOT_A_GOAL, validation.reasoning)

    generated = await run_gemini(
        generate_onboarding_questions, payload.prompt, validation.reasoning, language
    )
    return [
        ObjectiveQuestion(
            question=q.question,
            options=[q.option_a, q.option_b, q.option_c, q.option_d],
            ai_model=generated.ai_model,
        )
        for q in generated.questions
    ]


@router.post("/study-plan", response_model=StudyPlanResponse)
@limiter.limit("20/minute")
async def study_plan(
    request: Request,
    payload: GoalCreationRequest,
    chosen: Annotated[Language | None, Depends(requested_language)],
):
    """
    Step 2: generate a stateless study-plan preview (goal name + markdown
    description) from the prompt and the user's onboarding answers. Not persisted.
    """
    language = output_language(chosen, payload.prompt)
    plan = await run_gemini(generate_study_plan, payload.prompt, payload.answers, language)
    return StudyPlanResponse(goal_name=plan.goal_name, description=plan.description)


@router.post("", response_model=GoalCreationResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("20/minute")
async def create_goal(
    request: Request,
    payload: GoalCommitRequest,
    current_user: Annotated[Student, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """
    Step 3 (AUTHED): persist the goal the user approved in the preview, store the
    onboarding it came from, make it the active goal, then fire the student chain
    in the background. No Gemini call of its own (#132): the wait it used to buy
    introduction screens for is now the standard questions this returns.

    The onboarding is *stored*, not handed to the chain: the chain's first step
    reads it from the database, so a run that fails is one the nightly run can do
    over (#88). It is read **as it stood when this returned**, which is what keeps
    the batch now in flight from seeing the standard questions the student is
    about to answer.
    """
    goal = await GoalRepository(db).create(
        Goal(student_id=current_user.id, name=payload.goal_name, description=payload.description)
    )
    await OnboardingRepository(db).save_onboarding(
        goal.id,
        payload.prompt,
        [(a.question, a.answer, a.total_seconds, a.ai_model) for a in payload.answers],
    )
    student_id = str(current_user.id)
    current_user.current_goal_id = goal.id
    await StudentRepository(db).update(current_user)
    await db.commit()

    kickoff_student_chain(student_id, onboarding_as_of=clock.now())

    return GoalCreationResponse(
        id=str(goal.id),
        name=goal.name,
        standard_questions=[
            StandardQuestionData(key=q.key, options=[o.key for o in q.options])
            for q in STANDARD_QUESTIONS
        ],
    )


@router.post("/{goal_id}/standard-answers", status_code=status.HTTP_204_NO_CONTENT)
async def standard_answers(
    payload: StandardAnswersRequest,
    goal: Annotated[Goal, Depends(get_owned_goal)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """What the student told us about himself while his first batch generated.

    Stored beside the rest of his onboarding, marked `ai_model = "system"`. The
    batch already in flight will not read them - `POST /goals` pinned its view of
    the onboarding to the moment it returned - and every generation after it
    will (#132). Answers so far are worth keeping, so a partial list is normal
    and an empty one is a no-op.
    """
    answers = [(a.question_key, a.option_key, a.total_seconds) for a in payload.answers]
    await OnboardingRepository(db).save_standard_answers(goal.id, resolve_standard_answers(answers))
    await db.commit()


@router.get("", response_model=list[GoalResponse])
async def list_goals(
    current_user: Annotated[Student, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Every goal of the student, newest first, with all the fields the goals list and
    the goal detail screen show (there is no per-goal GET)."""
    goals = await GoalRepository(db).list_by_student(current_user.id)
    return [
        GoalResponse(
            id=str(goal.id),
            name=goal.name,
            description=goal.description,
            current_elo=goal.rating,
            is_active=goal.id == current_user.current_goal_id,
            created_at=goal.created_at,
            updated_at=goal.updated_at,
        )
        for goal in goals
    ]


@router.put("/{goal_id}/set-active", response_model=SetActiveGoalResponse)
async def set_active_goal(
    goal: Annotated[Goal, Depends(get_owned_goal)],
    current_user: Annotated[Student, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Make one of the student's goals the active one (students.current_goal_id).
    Someone else's goal, or a missing one, is 404 (see get_owned_goal)."""
    goal_id = goal.id  # read before commit: the production session expires on commit
    current_user.current_goal_id = goal_id
    await StudentRepository(db).update(current_user)
    await db.commit()
    return SetActiveGoalResponse(goal_id=str(goal_id))


@router.delete("/{goal_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_goal(
    goal: Annotated[Goal, Depends(get_owned_goal)],
    current_user: Annotated[Student, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Delete a goal and everything under it. The database does the cascading
    (ON DELETE CASCADE on the goal's rows, SET NULL on students.current_goal_id), so
    the in-memory student is refreshed afterwards: it may still hold the old id."""
    await GoalRepository(db).delete(goal.id)
    await db.commit()
    await db.refresh(current_user)
