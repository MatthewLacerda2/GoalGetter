from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.schemas.goal import GoalCreationFollowUpQuestionsRequest, GoalStudyPlanRequest
from backend.services.gemini.onboarding.schema import GoalValidation, FollowUpValidation
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

def isGoalValidated(goalValidation: GoalValidation) -> bool :
    
    is_valid = goalValidation.is_harmless and goalValidation.is_achievable and goalValidation.makes_sense
    
    return is_valid

def get_follow_up_validation(study_plan_request: GoalStudyPlanRequest) -> FollowUpValidation:
    
    client = get_client()
    model = "gemini-2.5-flash"
    full_prompt = get_follow_up_validation_prompt(study_plan_request)
    config = get_gemini_config(FollowUpValidation.model_json_schema())
    
    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    
    return FollowUpValidation.model_validate_json(json_response)

def isFollowUpValidated(study_plan_request: FollowUpValidation) -> bool:
    
    is_valid = study_plan_request.has_enough_information and study_plan_request.makes_sense and study_plan_request.is_harmless and study_plan_request.is_achievable
    
    return is_valid