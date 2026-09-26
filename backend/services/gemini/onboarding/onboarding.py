import logging

from backend.core.language import Language
from backend.services.gemini.onboarding.onboarding_prompts import (
    MAX_WORDS,
    get_onboarding_questions_prompt,
)
from backend.services.gemini.onboarding.schema import GeminiOnboardingQuestionsResponse
from backend.utils.envs import GEMINI_PREMIUM_MODEL
from backend.utils.gemini.gemini_configs import get_client, get_gemini_config

logger = logging.getLogger(__name__)


def generate_onboarding_questions(
    goal_name: str, goal_description: str, language: Language
) -> GeminiOnboardingQuestionsResponse:
    """The onboarding's questions, written for this student.

    **The prompt is the whole guard on their length** (#173). A question over
    `MAX_WORDS` is logged, not refused and not cut: refusing fails the student's
    onboarding over a long option, and cutting leaves a sentence with no end.
    The log is how a prompt that stopped being obeyed gets noticed.
    """
    client = get_client()
    model = GEMINI_PREMIUM_MODEL
    full_prompt = get_onboarding_questions_prompt(goal_name, goal_description, language)
    config = get_gemini_config(GeminiOnboardingQuestionsResponse.model_json_schema())

    response = client.models.generate_content(model=model, contents=full_prompt, config=config)

    generated = GeminiOnboardingQuestionsResponse.model_validate_json(response.text)
    too_long = over_word_limit(generated)
    if too_long:
        logger.warning("Onboarding: %d texts over %d words: %s", len(too_long), MAX_WORDS, too_long)
    return generated


def over_word_limit(generated: GeminiOnboardingQuestionsResponse) -> list[str]:
    """Every question or option longer than `MAX_WORDS` words."""
    texts = [
        text
        for q in generated.questions
        for text in (q.question, q.option_a, q.option_b, q.option_c, q.option_d)
    ]
    return [text for text in texts if len(text.split()) > MAX_WORDS]
