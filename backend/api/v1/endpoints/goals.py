from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.concurrency import run_in_threadpool
from backend.core.security import get_current_user
from backend.models.student import Student
from backend.schemas.goal import ObjectiveQuestionsRequest, ObjectiveQuestion
from backend.services.gemini.onboarding.goal_validation import get_prompt_validation, is_goal_validated
from backend.services.gemini.onboarding.onboarding import generate_onboarding_questions

router = APIRouter()

@router.post("/objective-questions", response_model=list[ObjectiveQuestion])
async def objective_questions(
    request: ObjectiveQuestionsRequest,
    current_user: Student = Depends(get_current_user),
):
    """
    Step 1 of goal creation: validate the prompt is a real goal, then generate
    clarifying multiple-choice questions to profile the user. Gemini calls are
    blocking, so they run off the event loop via the threadpool.
    """
    validation = await run_in_threadpool(get_prompt_validation, request.prompt)
    if not is_goal_validated(validation):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=validation.reasoning)

    generated = await run_in_threadpool(
        generate_onboarding_questions, request.prompt, validation.reasoning
    )
    return [
        ObjectiveQuestion(
            question=q.question, options=[q.option_a, q.option_b, q.option_c, q.option_d]
        )
        for q in generated.questions
    ]
