from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from backend.api.v1.goal_dependencies import get_owned_goal
from backend.core.database import get_db
from backend.core.rate_limiter import limiter
from backend.core.security import get_current_user
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
    IntroductionScreenData,
    ObjectiveQuestion,
    ObjectiveQuestionsRequest,
    SetActiveGoalResponse,
    StudyPlanResponse,
)
from backend.services.gemini.onboarding.goal_validation import (
    get_prompt_validation,
    is_goal_validated,
)
from backend.services.gemini.onboarding.introduction import generate_introduction_screens
from backend.services.gemini.onboarding.onboarding import generate_onboarding_questions
from backend.services.gemini.onboarding.study_plan import generate_study_plan
from backend.services.jobs.student_chain import kickoff_student_chain
from backend.utils.gemini.gemini_guard import run_gemini

router = APIRouter()

# Goal-creation (onboarding) endpoints are intentionally PUBLIC so anyone can try
# the app without signing up. Each one calls Gemini, so it's rate-limited to
# 20/minute per client to bound AI cost (the global default is 10/second; see
# backend/core/rate_limiter.py).
#
# NOTE: the backend runs with multiple uvicorn workers and slowapi's default
# in-memory storage is per-process, so this cap is enforced per worker (looser
# than 20/min overall). Switch to a single worker or shared storage (Redis) if
# an exact global cap is required.


@router.post("/objective-questions", response_model=list[ObjectiveQuestion])
@limiter.limit("20/minute")
async def objective_questions(request: Request, payload: ObjectiveQuestionsRequest):
    """
    Step 1: validate the prompt is a real goal, then generate clarifying
    multiple-choice questions. Blocking Gemini calls run off the event loop.
    """
    validation = await run_gemini(get_prompt_validation, payload.prompt)
    if not is_goal_validated(validation):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=validation.reasoning)

    generated = await run_gemini(
        generate_onboarding_questions, payload.prompt, validation.reasoning
    )
    return [
        ObjectiveQuestion(
            question=q.question, options=[q.option_a, q.option_b, q.option_c, q.option_d]
        )
        for q in generated.questions
    ]


@router.post("/study-plan", response_model=StudyPlanResponse)
@limiter.limit("20/minute")
async def study_plan(request: Request, payload: GoalCreationRequest):
    """
    Step 2: generate a stateless study-plan preview (goal name + markdown
    description) from the prompt and the user's onboarding answers. Not persisted.
    """
    plan = await run_gemini(generate_study_plan, payload.prompt, payload.answers)
    return StudyPlanResponse(goal_name=plan.goal_name, description=plan.description)


@router.post("", response_model=GoalCreationResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("20/minute")
async def create_goal(
    request: Request,
    payload: GoalCommitRequest,
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Step 3 (AUTHED): persist the goal the user approved in the preview, store the
    onboarding it came from, make it the active goal, generate the introduction
    screens (the only synchronous Gemini call), then fire the student chain in the
    background — that is what the introduction screens buy time for.

    The onboarding is *stored*, not handed to the chain: the chain's first step
    reads it from the database, so a run that fails is one the nightly run can do
    over (#88).
    """
    intro = await run_gemini(generate_introduction_screens, payload.goal_name, payload.description)

    goal = await GoalRepository(db).create(
        Goal(student_id=current_user.id, name=payload.goal_name, description=payload.description)
    )
    await OnboardingRepository(db).save_onboarding(
        goal.id, payload.prompt, [(a.question, a.answer) for a in payload.answers]
    )
    student_id = str(current_user.id)
    current_user.current_goal_id = goal.id
    await StudentRepository(db).update(current_user)
    await db.commit()

    kickoff_student_chain(student_id)

    return GoalCreationResponse(
        id=str(goal.id),
        name=goal.name,
        introduction_screen_data=[
            IntroductionScreenData(icon=s.icon.value, title=s.title, text=s.text)
            for s in intro.screens
        ],
    )


@router.get("", response_model=list[GoalResponse])
async def list_goals(
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
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
    goal: Goal = Depends(get_owned_goal),
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
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
    goal: Goal = Depends(get_owned_goal),
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Delete a goal and everything under it. The database does the cascading
    (ON DELETE CASCADE on the goal's rows, SET NULL on students.current_goal_id), so
    the in-memory student is refreshed afterwards: it may still hold the old id."""
    await GoalRepository(db).delete(goal.id)
    await db.commit()
    await db.refresh(current_user)
