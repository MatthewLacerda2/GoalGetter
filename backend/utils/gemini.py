from dotenv import load_dotenv
from google.genai import Client
from google.genai.types import GenerateContentConfig
import logging
from backend.core.config import settings
from backend.schemas.roadmap import RoadmapInitiationResponse, RoadmapInitiationRequest, RoadmapCreationResponse, RoadmapCreationRequest
from backend.utils.prompts import get_roadmap_initiation_prompt, get_roadmap_creation_prompt

logger = logging.getLogger(__name__)
load_dotenv()

def get_client():
    #credentials = Credentials(
        #token=None,  # Token is automatically fetched using refresh token
        #refresh_token=settings.GOOGLE_REFRESH_TOKEN,
        #client_id=settings.GOOGLE_CLIENT_ID,
        #client_secret=settings.GOOGLE_CLIENT_SECRET,
        #token_uri='https://oauth2.googleapis.com/token',  # This is the standard Google OAuth2 token endpoint
    #)
    
    return Client(
        api_key=settings.GEMINI_API_KEY,
        #vertexai=True,
        #project=GOOGLE_PROJECT_ID,
        #location="global",
        #credentials=credentials    #TODO: uncomment this when you figure the values out. They were fine until they weren't
    )

gemini_temperature = 0.0

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

def get_gemini_roadmap_creation(creation_request: RoadmapCreationRequest) -> RoadmapCreationResponse:
    client = get_client()
    full_prompt = get_roadmap_creation_prompt(creation_request)
    
    response = client.models.generate_content(
        model="gemini-2.5-flash", contents=full_prompt, config=GenerateContentConfig(
        response_mime_type='application/json',
        response_schema=RoadmapCreationResponse.model_json_schema(),
        automatic_function_calling={"disable": True}
    ),)
    
    json_response = response.text
    
    return RoadmapCreationResponse.model_validate_json(json_response)