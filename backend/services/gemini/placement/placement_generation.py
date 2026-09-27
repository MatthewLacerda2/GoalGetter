from backend.core.config import settings
from backend.core.language import Language
from backend.services.gemini.client.gemini_configs import get_client, get_gemini_config
from backend.services.gemini.lesson.schema import GeminiLessonQuestionsResponse
from backend.services.gemini.placement.prompt import get_placement_prompt
from backend.services.gemini.student_context.schema import GeminiStudentContext


def generate_placement_questions(
    goal_name: str,
    asked: str,
    contexts: list[GeminiStudentContext],
    language: Language,
) -> GeminiLessonQuestionsResponse:
    """A new goal's first `PLACEMENT_SIZE` questions (the user, 2026-09-26).

    Its own prompt because it has its own job: with nothing answered yet there
    is no "one step past what he holds" to aim at, so these start at the most
    basic and climb, and his answers to them are the first measurement of him.
    The same shape as a lesson batch, stored in the same table and served the
    same way.

    `asked` is what the student typed, not the goal's description: the
    description is Gemini's study plan and can be narrower than what he asked.
    """
    prompt = get_placement_prompt(goal_name, asked, contexts, language)
    config = get_gemini_config(GeminiLessonQuestionsResponse.model_json_schema())
    # Held in a name on purpose: google-genai closes its HTTP client when the
    # Client is garbage-collected, and `get_client().models.generate_content(...)`
    # drops the Client mid-call - "Cannot send a request, as the client has been
    # closed" (seen on the preview, 2026-09-26).
    client = get_client()
    response = client.models.generate_content(
        model=settings.GEMINI_FAST_MODEL, contents=prompt, config=config
    )
    return GeminiLessonQuestionsResponse.model_validate_json(response.text)
