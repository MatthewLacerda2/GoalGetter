from backend.services.gemini.student_context.prompt import (
    get_context_review_prompt,
    get_student_context_prompt,
)
from backend.services.gemini.student_context.schema import (
    GeminiContextReview,
    GeminiStudentContext,
    GeminiStudentContextResponse,
    StudentGoal,
)
from backend.utils.envs import GEMINI_PREMIUM_MODEL
from backend.utils.gemini.gemini_configs import get_client, get_gemini_config


def gemini_generate_student_context(
    goals: list[StudentGoal],
    onboarding_prompt: str | None = None,
    questions_answers: list[tuple[str, str]] | None = None,
) -> GeminiStudentContextResponse:
    """The first reading of a learner, from their onboarding and every goal
    they have (#87). One context per student, not one per goal."""
    client = get_client()
    model = GEMINI_PREMIUM_MODEL
    config = get_gemini_config(GeminiStudentContext.model_json_schema())

    full_prompt = get_student_context_prompt(
        goals=goals,
        onboarding_prompt=onboarding_prompt,
        questions_answers=questions_answers,
    )

    response = client.models.generate_content(model=model, contents=full_prompt, config=config)

    context = GeminiStudentContext.model_validate_json(response.text)
    return GeminiStudentContextResponse(
        state=context.state, metacognition=context.metacognition, ai_model=model
    )


def gemini_review_student_context(
    goals: list[StudentGoal],
    contexts: list[GeminiStudentContext],
    recent_answers: list[dict],
    recent_chat_history: list[dict],
    questions_answers: list[tuple[str, str]] | None = None,
) -> GeminiContextReview:
    """Ask which of the student's standing readings went stale, and what to add
    (#90). Replaces the periodic rewrite: the model is already reading the
    recent lessons, so it is the one that says what changed - and "nothing
    changed" is an answer it is allowed to give cheaply.

    `questions_answers` is what the student told us about himself while creating
    his goals - the standard questions included, which the first batch never saw
    (#132). Facts about a person do not go stale the way a reading of him does,
    so they are shown to every review rather than only to the first impression.
    """
    client = get_client()
    model = GEMINI_PREMIUM_MODEL
    config = get_gemini_config(GeminiContextReview.model_json_schema())

    full_prompt = get_context_review_prompt(
        goals=goals,
        contexts=contexts,
        recent_answers=recent_answers,
        recent_chat_history=recent_chat_history,
        questions_answers=questions_answers,
    )

    response = client.models.generate_content(model=model, contents=full_prompt, config=config)

    return GeminiContextReview.model_validate_json(response.text)
