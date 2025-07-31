from fastapi import APIRouter
from backend.schemas.roadmap import RoadmapInitiationRequest, RoadmapInitiationResponse
from backend.utils.gemini import get_gemini_follow_up_questions

router = APIRouter(prefix="/roadmap", tags=["roadmap"])

@router.post("/initiation", response_model=RoadmapInitiationResponse)
async def initiate_roadmap(request: RoadmapInitiationRequest):
    """
    Initiate the roadmap creation process by analyzing the user's goal prompt
    Generats follow-up questions to better understand their needs.
    """    
    return get_gemini_follow_up_questions(request)