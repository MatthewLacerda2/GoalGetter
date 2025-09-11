from dotenv import load_dotenv
from google.genai import Client
from google.genai.types import GenerateContentConfig, ThinkingConfig
import logging
from backend.core.config import settings
from backend.schemas.goal import GoalCreationFollowUpQuestionsResponse, GoalCreationFollowUpQuestionsRequest
from backend.utils.prompts import get_goal_follow_up_questions_prompt

logger = logging.getLogger(__name__)
load_dotenv()

def get_client():    
    return Client(api_key=settings.GEMINI_API_KEY)

def get_gemini_follow_up_questions(initiation_request: GoalCreationFollowUpQuestionsRequest) -> GoalCreationFollowUpQuestionsResponse:
    
    client = get_client()
    full_prompt = get_goal_follow_up_questions_prompt(initiation_request)
    
    response = client.models.generate_content(
        model="gemini-2.5-flash", contents=full_prompt, config=GenerateContentConfig(
            response_mime_type='application/json',
            thinking_config=ThinkingConfig(
                thinking_budget=0
            ),
            response_schema=GoalCreationFollowUpQuestionsResponse.model_json_schema(),
            automatic_function_calling={"disable": True}
        )
    )
    
    json_response = response.text
    
    return GoalCreationFollowUpQuestionsResponse.model_validate_json(json_response)