from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.utils.gemini.onboarding.onboarding_prompts import get_goal_follow_up_questions_prompt, get_goal_study_plan_prompt
from backend.schemas.goal import GoalCreationFollowUpQuestionsRequest, GoalCreationFollowUpQuestionsResponse, GoalStudyPlanRequest, GoalStudyPlanResponse

def get_gemini_follow_up_questions(initiation_request: GoalCreationFollowUpQuestionsRequest) -> GoalCreationFollowUpQuestionsResponse:
    
    client = get_client()
    model = "gemini-2.5-flash"
    full_prompt = get_goal_follow_up_questions_prompt(initiation_request)
    config = get_gemini_config(GoalCreationFollowUpQuestionsResponse.model_json_schema())
    
    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    
    return GoalCreationFollowUpQuestionsResponse.model_validate_json(json_response)

def get_gemini_study_plan(study_plan_request: GoalStudyPlanRequest) -> GoalStudyPlanResponse:
    
    client = get_client()
    model = "gemini-2.5-pro"
    full_prompt = get_goal_study_plan_prompt(study_plan_request)
    config = get_gemini_config(GoalStudyPlanResponse.model_json_schema())
    
    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    
    return GoalStudyPlanResponse.model_validate_json(json_response)