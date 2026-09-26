from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from backend.api.v1.goal_dependencies import get_owned_goal
from backend.core import clock
from backend.core.database import get_db
from backend.core.language import Language, requested_language
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
    ObjectiveQuestion,
    ObjectiveQuestionsRequest,
    SetActiveGoalResponse,
    StandardAnswersRequest,
    StandardQuestionData,
    StudyPlanResponse,
)
from backend.services.gemini.onboarding.goal_validation import (
    get_prompt_validation,
    is_goal_validated,
)
from backend.services.gemini.onboarding.onboarding import generate_onboarding_questions
from backend.services.gemini.onboarding.study_plan import generate_study_plan
from backend.services.gemini.output_language import output_language
from backend.services.jobs.student_chain import kickoff_student_chain
from backend.services.onboarding.standard_questions import STANDARD_QUESTIONS
from backend.utils.envs import GEMINI_PREMIUM_MODEL
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
async def objective_questions(
    request: Request,
    payload: ObjectiveQuestionsRequest,
    chosen: Language | None = Depends(requested_language),
):
    """
    Step 1: validate the prompt is a real goal, then generate clarifying
    multiple-choice questions. Blocking Gemini calls run off the event loop.

    Public, so there is no student row: the language is the header the app
    sends (#172), else the one the prompt is written in (#173).
    """
    language = output_language(chosen, payload.prompt)
    validation = await run_gemini(get_prompt_validation, payload.prompt, language)
    if not is_goal_validated(validation):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=validation.reasoning)

    generated = await run_gemini(
        generate_onboarding_questions, payload.prompt, validation.reasoning, language
    )
    return [
        ObjectiveQuestion(
            question=q.question, options=[q.option_a, q.option_b, q.option_c, q.option_d]
        )
        for q in generated.questions
    ]


@router.post("/study-plan", response_model=StudyPlanResponse)
@limiter.limit("20/minute")
async def study_plan(
    request: Request,
    payload: GoalCreationRequest,
    chosen: Language | None = Depends(requested_language),
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
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
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
        [(a.question, a.answer, a.total_seconds) for a in payload.answers],
        GEMINI_PREMIUM_MODEL,
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
    goal: Goal = Depends(get_owned_goal),
    db: AsyncSession = Depends(get_db),
):
    """What the student told us about himself while his first batch generated.

    Stored beside the rest of his onboarding, marked `ai_model = "system"`. The
    batch already in flight will not read them - `POST /goals` pinned its view of
    the onboarding to the moment it returned - and every generation after it
    will (#132). Answers so far are worth keeping, so a partial list is normal
    and an empty one is a no-op.
    """
    await OnboardingRepository(db).save_standard_answers(
        goal.id, [(a.question_key, a.option_key, a.total_seconds) for a in payload.answers]
    )
    await db.commit()


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
