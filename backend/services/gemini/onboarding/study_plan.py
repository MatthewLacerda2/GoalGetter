from backend.core.config import settings
from backend.core.language import Language
from backend.schemas.goal import ObjectiveAnswer
from backend.services.gemini.client.gemini_call import generate
from backend.services.gemini.onboarding.schema import GeminiStudyPlan
from backend.services.gemini.onboarding.study_plan_prompt import get_study_plan_prompt


async def generate_study_plan(
    prompt: str, answers: list[ObjectiveAnswer], language: Language
) -> GeminiStudyPlan:

    return await generate(
        settings.GEMINI_PREMIUM_MODEL,
        get_study_plan_prompt(prompt, answers, language),
        GeminiStudyPlan,
    )
