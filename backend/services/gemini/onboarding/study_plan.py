from backend.core.config import settings
from backend.core.language import Language
from backend.schemas.goal import ObjectiveAnswer
from backend.services.gemini.client.gemini_configs import get_client, get_gemini_config
from backend.services.gemini.onboarding.schema import GeminiStudyPlan
from backend.services.gemini.onboarding.study_plan_prompt import get_study_plan_prompt


def generate_study_plan(
    prompt: str, answers: list[ObjectiveAnswer], language: Language
) -> GeminiStudyPlan:

    client = get_client()
    config = get_gemini_config(GeminiStudyPlan.model_json_schema())

    response = client.models.generate_content(
        model=settings.GEMINI_PREMIUM_MODEL,
        contents=get_study_plan_prompt(prompt, answers, language),
        config=config,
    )

    return GeminiStudyPlan.model_validate_json(response.text)
