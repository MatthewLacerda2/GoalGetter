from fastapi import APIRouter, Depends, HTTPException
from backend.core.security import get_current_user
from backend.models.student import Student
from backend.schemas.goal import GoalCreationFollowUpQuestionsRequest, GoalCreationFollowUpQuestionsResponse
from backend.utils.gemini.onboarding import get_gemini_follow_up_questions

router = APIRouter()

@router.post(
    "",
    status_code=200,
    response_model=GoalCreationFollowUpQuestionsResponse,
    description="Initiate the onboarding process by analyzing the user's goal prompt and generating follow-up questions.")
async def onboarding_questions(request: GoalCreationFollowUpQuestionsRequest, user: Student = Depends(get_current_user)):
    
    if user.goal_name is not None:
        raise HTTPException(status_code=400, detail="User already has a goal")
    
    return get_gemini_follow_up_questions(request)