from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.utils.envs import GEMINI_PREMIUM_MODEL
from backend.services.gemini.onboarding.onboarding_prompts import get_onboarding_questions_prompt
from backend.services.gemini.onboarding.schema import GeminiOnboardingQuestionsResponse

def generate_onboarding_questions(goal_name: str, goal_description: str) -> GeminiOnboardingQuestionsResponse:
    client = get_client()
    model = GEMINI_PREMIUM_MODEL
    full_prompt = get_onboarding_questions_prompt(goal_name, goal_description)
    config = get_gemini_config(GeminiOnboardingQuestionsResponse.model_json_schema())
    
    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    return GeminiOnboardingQuestionsResponse.model_validate_json(json_response)