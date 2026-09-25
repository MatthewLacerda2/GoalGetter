from backend.services.gemini.lesson.prompt import get_lesson_generation_prompt
from backend.services.gemini.lesson.schema import GeminiLessonQuestionsResponse
from backend.services.gemini.student_context.schema import GeminiStudentContext
from backend.utils.envs import GEMINI_FAST_MODEL, QUESTIONS_PER_LESSON
from backend.utils.gemini.gemini_configs import get_client, get_gemini_config


def generate_lesson_questions(
    goal_name: str,
    goal_description: str,
    frontier: str,
    rating: int,
    contexts: list[GeminiStudentContext],
    recent_errors: list[str] | None = None,
    count: int = QUESTIONS_PER_LESSON,
) -> GeminiLessonQuestionsResponse:
    """Questions for one goal, written for the student the contexts describe
    (#87): the same student-wide contexts the tutor reads, plus this goal.

    They aim at `frontier`, not at the goal's description (#133): the
    description is what he asked for on day one, and the frontier is the
    threshold the app is teaching him at tonight.

    `count` is how many to ask for. It is an argument and not a constant in the
    prompt because the nightly run asks for exactly what tomorrow is short of
    (#91), which is a different number every night."""
    client = get_client()
    model = GEMINI_FAST_MODEL
    full_prompt = get_lesson_generation_prompt(
        goal_name=goal_name,
        goal_description=goal_description,
        frontier=frontier,
        rating=rating,
        contexts=contexts,
        recent_errors=recent_errors,
        count=count,
    )
    config = get_gemini_config(GeminiLessonQuestionsResponse.model_json_schema())

    response = client.models.generate_content(model=model, contents=full_prompt, config=config)

    json_response = response.text
    return GeminiLessonQuestionsResponse.model_validate_json(json_response)
