from backend.core.language import Language
from backend.services.gemini.lesson.prompt import get_lesson_generation_prompt
from backend.services.gemini.lesson.schema import AnsweredQuestion, GeminiLessonQuestionsResponse
from backend.services.gemini.student_context.schema import GeminiStudentContext
from backend.utils.envs import GEMINI_FAST_MODEL
from backend.utils.gemini.gemini_configs import get_client, get_gemini_config


def generate_lesson_questions(
    goal_name: str,
    goal_description: str,
    frontier: str,
    rating: int,
    target_difficulty: int,
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

    `target_difficulty` is a rating, above the student's own, and it reaches the
    prompt as that number rather than as the word "harder" (#135): a batch is
    bought because the bank has become too easy, so it has to be written for
    where he is going.

    **How many is not an argument.** Every generation asks for exactly
    `QUESTIONS_PER_GENERATION`; the old variable count existed to fill a gap in
    the bank, and there is no gap to fill any more (#135)."""
    client = get_client()
    model = GEMINI_FAST_MODEL
    full_prompt = get_lesson_generation_prompt(
        goal_name=goal_name,
        goal_description=goal_description,
        frontier=frontier,
        rating=rating,
        target_difficulty=target_difficulty,
        contexts=contexts,
        answered_right=answered_right,
        answered_wrong=answered_wrong,
        language=language,
    )
    config = get_gemini_config(GeminiLessonQuestionsResponse.model_json_schema())

    response = client.models.generate_content(model=model, contents=full_prompt, config=config)

    json_response = response.text
    return GeminiLessonQuestionsResponse.model_validate_json(json_response)
