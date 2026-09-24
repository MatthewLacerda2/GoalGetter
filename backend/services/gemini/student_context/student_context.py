from backend.services.gemini.student_context.prompt import (
    get_periodic_student_context_prompt,
    get_student_context_prompt,
)
from backend.services.gemini.student_context.schema import (
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


def gemini_generate_periodic_student_context(
    goals: list[StudentGoal],
    previous_state: str,
    previous_metacognition: str,
    recent_lesson_results: list[dict],
    recent_chat_history: list[dict],
) -> GeminiStudentContextResponse:
    """Revise the reading of a learner from their recent lessons and chats,
    across every goal they study (#87)."""
    client = get_client()
    model = GEMINI_PREMIUM_MODEL
    config = get_gemini_config(GeminiStudentContext.model_json_schema())

    full_prompt = get_periodic_student_context_prompt(
        goals=goals,
        previous_state=previous_state,
        previous_metacognition=previous_metacognition,
        recent_lesson_results=recent_lesson_results,
        recent_chat_history=recent_chat_history,
    )

    response = client.models.generate_content(model=model, contents=full_prompt, config=config)

    context = GeminiStudentContext.model_validate_json(response.text)
    return GeminiStudentContextResponse(
        state=context.state, metacognition=context.metacognition, ai_model=model
    )
