from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession
from backend.core.database import get_db
from backend.core.rate_limiter import limiter
from backend.core.security import get_current_user
from backend.models.goal import Goal
from backend.models.student import Student
from backend.repositories.goal_repository import GoalRepository
from backend.repositories.student_repository import StudentRepository
from backend.schemas.goal import (
    ObjectiveQuestionsRequest,
    ObjectiveQuestion,
    GoalCreationRequest,
    StudyPlanResponse,
    GoalCommitRequest,
    GoalCreationResponse,
    IntroductionScreenData,
)
from backend.services.gemini.onboarding.goal_validation import get_prompt_validation, is_goal_validated
from backend.services.gemini.onboarding.onboarding import generate_onboarding_questions
from backend.services.gemini.onboarding.study_plan import generate_study_plan
from backend.services.gemini.onboarding.introduction import generate_introduction_screens
from backend.services.jobs.goal_jobs import kickoff_resource_scraping, kickoff_lessons_generation
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
    Step 3 (AUTHED): persist the goal the user approved in the preview, make it the
    active goal, generate the introduction screens (the only synchronous Gemini call),
    then fire the slow setup jobs (resources, lessons) in the background — those are
    what the introduction screens buy time for.
    """
    intro = await run_gemini(generate_introduction_screens, payload.goal_name, payload.description)

    goal = await GoalRepository(db).create(
        Goal(student_id=current_user.id, name=payload.goal_name, description=payload.description)
    )
    current_user.current_goal_id = goal.id
    await StudentRepository(db).update(current_user)
    await db.commit()

    kickoff_resource_scraping(str(goal.id))
    kickoff_lessons_generation(str(goal.id))

    return GoalCreationResponse(
        id=str(goal.id),
        name=goal.name,
        introduction_screen_data=[
            IntroductionScreenData(icon=s.icon.value, title=s.title, text=s.text)
            for s in intro.screens
        ],
    )
