from backend.core.config import settings
from backend.core.language import Language
from backend.services.gemini.client.gemini_call import generate
from backend.services.gemini.lesson.schema import GeminiLessonQuestionsResponse
from backend.services.gemini.placement.prompt import get_placement_prompt
from backend.services.gemini.student_context.schema import GeminiStudentContext


async def generate_placement_questions(
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
    return await generate(settings.GEMINI_FAST_MODEL, prompt, GeminiLessonQuestionsResponse)
