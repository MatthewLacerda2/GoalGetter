from backend.core.config import settings
from backend.core.language import Language
from backend.services.gemini.client.gemini_call import generate
from backend.services.gemini.onboarding.goal_validation_prompt import get_goal_validation_prompt
from backend.services.gemini.onboarding.schema import GeminiGoalValidation


async def get_prompt_validation(prompt: str, language: Language) -> GeminiGoalValidation:

    return await generate(
        settings.GEMINI_PREMIUM_MODEL,
        get_goal_validation_prompt(prompt, language),
        GeminiGoalValidation,
    )


def is_goal_validated(validation: GeminiGoalValidation) -> bool:

    return validation.is_harmless and validation.is_achievable and validation.makes_sense
