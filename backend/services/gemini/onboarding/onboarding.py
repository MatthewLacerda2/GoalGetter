import logging

from backend.core.config import settings
from backend.core.language import Language
from backend.services.gemini.client.gemini_call import generate
from backend.services.gemini.onboarding.onboarding_prompts import (
    MAX_WORDS,
    get_onboarding_questions_prompt,
)
from backend.services.gemini.onboarding.schema import (
    GeminiOnboardingQuestionsResponse,
    OnboardingQuestions,
)

logger = logging.getLogger(__name__)


async def generate_onboarding_questions(
    goal_name: str, goal_description: str, language: Language
) -> OnboardingQuestions:
    """The onboarding's questions, written for this student, and the model that
    wrote them - the app sends it back with each answer, so the row that stores
    the answer names its true author (#216).

    **The prompt is the whole guard on their length** (#173). A question over
    `MAX_WORDS` is logged, not refused and not cut: refusing fails the student's
    onboarding over a long option, and cutting leaves a sentence with no end.
    The log is how a prompt that stopped being obeyed gets noticed.
    """
    model = settings.GEMINI_PREMIUM_MODEL
    full_prompt = get_onboarding_questions_prompt(goal_name, goal_description, language)

    generated = await generate(model, full_prompt, GeminiOnboardingQuestionsResponse)
    too_long = over_word_limit(generated)
    if too_long:
        logger.warning("Onboarding: %d texts over %d words: %s", len(too_long), MAX_WORDS, too_long)
    return OnboardingQuestions(questions=generated.questions, ai_model=model)


def over_word_limit(generated: GeminiOnboardingQuestionsResponse) -> list[str]:
    """Every question or option longer than `MAX_WORDS` words."""
    texts = [
        text
        for q in generated.questions
        for text in (q.question, q.option_a, q.option_b, q.option_c, q.option_d)
    ]
    return [text for text in texts if len(text.split()) > MAX_WORDS]
