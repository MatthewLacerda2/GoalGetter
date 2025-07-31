from fastapi import APIRouter
from backend.schemas.roadmap import RoadmapInitiationRequest, RoadmapInitiationResponse, RoadmapCreationRequest, RoadmapCreationResponse
from backend.utils.gemini import get_gemini_follow_up_questions, get_gemini_roadmap_creation

router = APIRouter()

@router.post(
    "/initiation",
    status_code=200,
    response_model=RoadmapInitiationResponse,
    description="Initiate the roadmap creation process by analyzing the user's goal prompt and generating follow-up questions.")
async def initiate_roadmap(request: RoadmapInitiationRequest):
    return get_gemini_follow_up_questions(request)

@router.post(
    "/creation",
    status_code=200,
    response_model=RoadmapCreationResponse,
    description="Create a roadmap based on the user's goal and follow-up questions.")
async def create_roadmap(request: RoadmapCreationRequest):
    return get_gemini_roadmap_creation(request)