from fastapi import APIRouter
from backend.schemas.goal import GoalCreationFollowUpQuestionsRequest, GoalCreationFollowUpQuestionsResponse
from backend.utils.gemini import get_gemini_follow_up_questions

router = APIRouter()

@router.post(
    "",
    status_code=200,
    response_model=GoalCreationFollowUpQuestionsResponse,
    description="Initiate the onboarding process by analyzing the user's goal prompt and generating follow-up questions.")
async def onboarding_questions(request: GoalCreationFollowUpQuestionsRequest):
    return get_gemini_follow_up_questions(request)