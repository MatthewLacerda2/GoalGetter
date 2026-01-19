import ollama
from ollama._types import ResponseError
from backend.schemas.goal import GoalCreationFollowUpQuestionsRequest, GoalStudyPlanRequest
from backend.services.ollama.onboarding.schema import OllamaGoalValidation, OllamaFollowUpValidation
from backend.services.ollama.onboarding.goal_validation_prompt import get_goal_validation_prompt, get_follow_up_validation_prompt

def get_prompt_validation(initiation_request: GoalCreationFollowUpQuestionsRequest) -> OllamaGoalValidation:
    
    model = "gpt-oss:120b-cloud"
    full_prompt = get_goal_validation_prompt(initiation_request.prompt)
    
    try:
        response: ollama.ChatResponse = ollama.chat(
            model=model,
            stream=False,
            messages=[
                {
                    "role": "user",
                    "content": full_prompt
                }
            ],
            format=OllamaGoalValidation.model_json_schema()
        )
        
        json_response = response.message.content
        
        return OllamaGoalValidation.model_validate_json(json_response)
    except ResponseError as e:
        raise Exception(f"Ollama API error {e.status_code}: {str(e)}")
    except Exception as e:
        raise Exception(f"Unexpected error: {type(e).__name__}: {e}")

def isGoalValidated(goalValidation: OllamaGoalValidation) -> bool:
    
    is_valid = goalValidation.is_harmless and goalValidation.is_achievable and goalValidation.makes_sense
    
    return is_valid

def get_follow_up_validation(study_plan_request: GoalStudyPlanRequest) -> OllamaFollowUpValidation:
    
    model = "gpt-oss:120b-cloud"
    full_prompt = get_follow_up_validation_prompt(study_plan_request)
    
    try:
        response: ollama.ChatResponse = ollama.chat(
            model=model,
            stream=False,
            messages=[
                {
                    "role": "user",
                    "content": full_prompt
                }
            ],
            format=OllamaFollowUpValidation.model_json_schema()
        )
        
        json_response = response.message.content
        
        return OllamaFollowUpValidation.model_validate_json(json_response)
    except ResponseError as e:
        raise Exception(f"Ollama API error {e.status_code}: {str(e)}")
    except Exception as e:
        raise Exception(f"Unexpected error: {type(e).__name__}: {e}")

def isFollowUpValidated(study_plan_request: OllamaFollowUpValidation) -> bool:
    
    is_valid = study_plan_request.has_enough_information and study_plan_request.makes_sense and study_plan_request.is_harmless and study_plan_request.is_achievable
    
    return is_valid
