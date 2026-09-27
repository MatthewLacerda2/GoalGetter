from backend.core.config import settings
from backend.core.language import Language
from backend.services.gemini.client.gemini_call import generate
from backend.services.gemini.student_context.prompt import (
    get_context_review_prompt,
    get_student_context_prompt,
)
from backend.services.gemini.student_context.schema import (
    GeminiContextReview,
    GeminiStudentContext,
    GeminiStudentContextResponse,
    RecentAnswer,
    RecentChat,
    StudentGoal,
)


async def gemini_generate_student_context(
    goals: list[StudentGoal],
    onboarding_prompt: str | None,
    questions_answers: list[tuple[str, str]] | None,
    language: Language,
) -> GeminiStudentContextResponse:
    """The first reading of a learner, from their onboarding and the goal they
    are working on (the user, 2026-09-26). One context per student, not one per goal."""
    model = settings.GEMINI_PREMIUM_MODEL
    full_prompt = get_student_context_prompt(
        goals=goals,
        onboarding_prompt=onboarding_prompt,
        questions_answers=questions_answers,
        language=language,
    )

    context = await generate(model, full_prompt, GeminiStudentContext)
    return GeminiStudentContextResponse(
        state=context.state, metacognition=context.metacognition, ai_model=model
    )


async def gemini_review_student_context(
    goals: list[StudentGoal],
    contexts: list[GeminiStudentContext],
    recent_answers: list[RecentAnswer],
    recent_chat_history: list[RecentChat],
    questions_answers: list[tuple[str, str]] | None,
    language: Language,
) -> GeminiContextReview:
    """Ask which of the student's standing readings went stale, and what to add,
    rather than rewriting them: the model is already reading the
    recent lessons, so it is the one that says what changed - and "nothing
    changed" is an answer it is allowed to give cheaply.

    `questions_answers` is what the student told us about himself while creating
    his goals - the standard questions included, which the first batch never saw.
    Facts about a person do not go stale the way a reading of him does,
    so they are shown to every review rather than only to the first impression.
    """
    full_prompt = get_context_review_prompt(
        goals=goals,
        contexts=contexts,
        recent_answers=recent_answers,
        recent_chat_history=recent_chat_history,
        questions_answers=questions_answers,
        language=language,
    )
    return await generate(settings.GEMINI_PREMIUM_MODEL, full_prompt, GeminiContextReview)
