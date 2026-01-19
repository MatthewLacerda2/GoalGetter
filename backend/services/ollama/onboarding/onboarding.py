import ollama
from ollama._types import ResponseError
from backend.services.ollama.onboarding.onboarding_prompts import get_goal_follow_up_questions_prompt, get_goal_study_plan_prompt
from backend.schemas.goal import GoalCreationFollowUpQuestionsRequest, GoalCreationFollowUpQuestionsResponse, GoalStudyPlanRequest, GoalStudyPlanResponse

def get_ollama_follow_up_questions(initiation_request: GoalCreationFollowUpQuestionsRequest) -> GoalCreationFollowUpQuestionsResponse:
    
    model = "gpt-oss:120b-cloud"
    full_prompt = get_goal_follow_up_questions_prompt(initiation_request.prompt)
    
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
            format=GoalCreationFollowUpQuestionsResponse.model_json_schema()
        )
        
        json_response = response.message.content
        
        return GoalCreationFollowUpQuestionsResponse.model_validate_json(json_response)
    except ResponseError as e:
        raise Exception(f"Ollama API error {e.status_code}: {str(e)}")
    except Exception as e:
        raise Exception(f"Unexpected error: {type(e).__name__}: {e}")

def get_ollama_study_plan(study_plan_request: GoalStudyPlanRequest) -> GoalStudyPlanResponse:
    
    model = "gpt-oss:120b-cloud"
    full_prompt = get_goal_study_plan_prompt(study_plan_request)
    
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
            format=GoalStudyPlanResponse.model_json_schema()
        )
        
        json_response = response.message.content
        
        return GoalStudyPlanResponse.model_validate_json(json_response)
    except ResponseError as e:
        raise Exception(f"Ollama API error {e.status_code}: {str(e)}")
    except Exception as e:
        raise Exception(f"Unexpected error: {type(e).__name__}: {e}")
