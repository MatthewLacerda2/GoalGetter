from backend.core.config import settings
from backend.core.language import Language
from backend.services.gemini.client.gemini_configs import get_client, get_gemini_config
from backend.services.gemini.lesson.prompt import get_lesson_generation_prompt
from backend.services.gemini.lesson.schema import AnsweredQuestion, GeminiLessonQuestionsResponse
from backend.services.gemini.student_context.schema import GeminiStudentContext


def generate_lesson_questions(
    goal_name: str,
    goal_description: str,
    frontier: str,
    contexts: list[GeminiStudentContext],
    answered_right: list[AnsweredQuestion] | None,
    answered_wrong: list[AnsweredQuestion] | None,
    language: Language,
) -> GeminiLessonQuestionsResponse:
    """Questions for one goal, written for the student the contexts describe
    (#87): the same student-wide contexts the tutor reads, plus this goal.

    They aim at `frontier`, not at the goal's description (#133): the
    description is what he asked for on day one, and the frontier is the
    threshold the app is teaching him at tonight.

    **No difficulty number reaches the prompt** (the user, 2026-09-26): a model
    cannot tell what "difficulty 1232" means. It is shown what he got right and
    asked for the simplest exercises one step past it - the evidence itself.

    **How many is not an argument.** Every generation asks for exactly
    `QUESTIONS_PER_GENERATION`; the old variable count existed to fill a gap in
    the bank, and there is no gap to fill any more (#135)."""
    client = get_client()
    model = settings.GEMINI_FAST_MODEL
    full_prompt = get_lesson_generation_prompt(
        goal_name=goal_name,
        goal_description=goal_description,
        frontier=frontier,
        contexts=contexts,
        answered_right=answered_right,
        answered_wrong=answered_wrong,
        language=language,
    )
    config = get_gemini_config(GeminiLessonQuestionsResponse.model_json_schema())

    response = client.models.generate_content(model=model, contents=full_prompt, config=config)

    json_response = response.text
    return GeminiLessonQuestionsResponse.model_validate_json(json_response)
