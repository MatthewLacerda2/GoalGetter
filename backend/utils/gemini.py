from dotenv import load_dotenv
from google.genai import Client
from google.genai.types import GenerateContentConfig
import logging
from backend.core.config import settings
from backend.schemas.roadmap import RoadmapInitiationResponse, RoadmapInitiationRequest
from backend.utils.prompts import get_roadmap_initiation_prompt

gemini_temperature = 0.0
logger = logging.getLogger(__name__)
load_dotenv()

def get_client():    
    return Client(api_key=settings.GEMINI_API_KEY)

def get_gemini_follow_up_questions(initiation_request: RoadmapInitiationRequest) -> RoadmapInitiationResponse:
    
    client = get_client()
    full_prompt = get_roadmap_initiation_prompt(initiation_request)
    
    response = client.models.generate_content(
        model="gemini-2.5-flash-lite", contents=full_prompt, config=GenerateContentConfig(
        response_mime_type='application/json',
        response_schema=RoadmapInitiationResponse.model_json_schema(),
        automatic_function_calling={"disable": True}
    ),)
    
    json_response = response.text
    
    return RoadmapInitiationResponse.model_validate_json(json_response)