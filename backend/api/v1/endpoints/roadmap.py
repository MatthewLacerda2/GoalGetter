from fastapi import APIRouter, HTTPException
from backend.schemas.roadmap import RoadmapInitiationRequest, RoadmapInitiationResponse

router = APIRouter(prefix="/roadmap", tags=["roadmap"])

@router.post("/initiation", response_model=RoadmapInitiationResponse)
async def initiate_roadmap(request: RoadmapInitiationRequest):
    """
    Initiate the roadmap creation process by analyzing the user's goal prompt
    and generating follow-up questions to better understand their needs.
    """
    try:
        # For now, return a simple response that matches the schema
        # In a real implementation, this would use AI to generate questions
        questions = [
            "What is your current skill level in this area?",
            "How much time can you dedicate to this goal?",
            "What is your preferred learning style?",
            "Do you have any specific constraints or preferences?"
        ]
        
        return RoadmapInitiationResponse(
            original_prompt=request.prompt,
            questions=questions
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) 