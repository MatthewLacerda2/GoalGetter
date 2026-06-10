from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.utils.envs import GEMINI_FAST_MODEL
from backend.services.gemini.onboarding.schema import GeminiIntroductionScreens
from backend.services.gemini.onboarding.introduction_prompt import get_introduction_prompt

def generate_introduction_screens(goal_name: str, description: str) -> GeminiIntroductionScreens:

    client = get_client()
    config = get_gemini_config(GeminiIntroductionScreens.model_json_schema())

    response = client.models.generate_content(
        model=GEMINI_FAST_MODEL, contents=get_introduction_prompt(goal_name, description), config=config
    )

    return GeminiIntroductionScreens.model_validate_json(response.text)
