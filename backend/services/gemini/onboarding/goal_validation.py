from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.schemas.goal import GoalCreationFollowUpQuestionsRequest, GoalStudyPlanRequest
from backend.services.gemini.onboarding.schema import GoalValidation
from backend.services.gemini.onboarding.goal_validation_prompt import get_goal_validation_prompt, get_follow_up_validation_prompt

def get_prompt_validation(initiation_request: GoalCreationFollowUpQuestionsRequest) -> GoalValidation:
    
    client = get_client()
    model = "gemini-2.5-flash-lite"
    full_prompt = get_goal_validation_prompt(initiation_request.prompt)
    config = get_gemini_config(GoalValidation.model_json_schema())
    
    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    
    return GoalValidation.model_validate_json(json_response)

def get_follow_up_validation(study_plan_request: GoalStudyPlanRequest) -> GoalValidation:
    
    client = get_client()
    model = "gemini-2.5-flash-lite"
    full_prompt = get_follow_up_validation_prompt(study_plan_request)
    config = get_gemini_config(GoalValidation.model_json_schema())
    
    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    
    return GoalValidation.model_validate_json(json_response)