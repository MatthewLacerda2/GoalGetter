from backend.core.config import settings
from backend.core.language import Language
from backend.services.gemini.client.gemini_configs import get_client, get_gemini_config
from backend.services.gemini.onboarding.goal_validation_prompt import get_goal_validation_prompt
from backend.services.gemini.onboarding.schema import GeminiGoalValidation


def get_prompt_validation(prompt: str, language: Language) -> GeminiGoalValidation:

    client = get_client()
    config = get_gemini_config(GeminiGoalValidation.model_json_schema())

    response = client.models.generate_content(
        model=settings.GEMINI_PREMIUM_MODEL,
        contents=get_goal_validation_prompt(prompt, language),
        config=config,
    )

    return GeminiGoalValidation.model_validate_json(response.text)


def is_goal_validated(validation: GeminiGoalValidation) -> bool:

    return validation.is_harmless and validation.is_achievable and validation.makes_sense
