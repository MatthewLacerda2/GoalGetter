from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.utils.envs import GEMINI_FAST_MODEL
from backend.services.gemini.lesson.prompt import get_lesson_generation_prompt
from backend.services.gemini.lesson.schema import GeminiLessonQuestionsResponse

def generate_lesson_questions(
    goal_name: str,
    goal_description: str,
    rating: int,
    state: str,
    metacognition: str,
    recent_errors: list[str] | None = None
) -> GeminiLessonQuestionsResponse:
    client = get_client()
    model = GEMINI_FAST_MODEL
    full_prompt = get_lesson_generation_prompt(
        goal_name=goal_name,
        goal_description=goal_description,
        rating=rating,
        state=state,
        metacognition=metacognition,
        recent_errors=recent_errors
    )
    config = get_gemini_config(GeminiLessonQuestionsResponse.model_json_schema())
    
    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    return GeminiLessonQuestionsResponse.model_validate_json(json_response)
