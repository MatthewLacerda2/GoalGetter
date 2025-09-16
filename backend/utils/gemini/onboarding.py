from backend.utils.gemini_configs import get_client, get_gemini_flash_config
from backend.utils.prompts import get_goal_follow_up_questions_prompt
from backend.schemas.goal import GoalCreationFollowUpQuestionsRequest, GoalCreationFollowUpQuestionsResponse

def get_gemini_follow_up_questions(initiation_request: GoalCreationFollowUpQuestionsRequest) -> GoalCreationFollowUpQuestionsResponse:
    
    client = get_client()
    model = "gemini-2.5-flash"
    config = get_gemini_flash_config(GoalCreationFollowUpQuestionsResponse.model_json_schema())
    full_prompt = get_goal_follow_up_questions_prompt(initiation_request)
    
    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    
    return GoalCreationFollowUpQuestionsResponse.model_validate_json(json_response)