from fastapi import APIRouter
from backend.schemas.roadmap import RoadmapInitiationRequest, RoadmapInitiationResponse
from backend.utils.gemini import get_gemini_follow_up_questions

router = APIRouter()

@router.post(
    "/initiation",
    status_code=200,
    response_model=RoadmapInitiationResponse,
    description="Initiate the roadmap creation process by analyzing the user's goal prompt and generating follow-up questions.")
async def initiate_roadmap(request: RoadmapInitiationRequest):
    return get_gemini_follow_up_questions(request)