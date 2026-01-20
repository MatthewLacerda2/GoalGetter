from typing import List, Optional

from backend.services.gemini.lesson_context.prompt import get_lesson_context_prompt
from backend.services.gemini.lesson_context.schema import (
    GeminiLessonContext,
    GeminiLessonContextResponse,
)
from backend.utils.gemini.gemini_configs import get_client, get_gemini_config


def gemini_lesson_context(
    goal_name: str,
    goal_description: str,
    objective_name: str,
    objective_description: str,
    questions_answers: List[tuple[str, str]],
    student_context: Optional[List[str]] = None,
) -> GeminiLessonContextResponse:
    """
    Generate lesson context using Gemini AI.

    Args:
        goal_name: Name of the student's goal
        goal_description: Description of the goal
        objective_name: Name of the current objective
        objective_description: Description of the current objective
        questions_answers: List of (question, answer) tuples from lessons
        student_context: Optional list of existing student context strings

    Returns:
        GeminiLessonContextResponse with state[], metacognition[], and ai_model
    """
    client = get_client()
    model = "gemini-2.5-flash-lite"
    config = get_gemini_config(GeminiLessonContext.model_json_schema())

    full_prompt = get_lesson_context_prompt(
        goal_name=goal_name,
        goal_description=goal_description,
        objective_name=objective_name,
        objective_description=objective_description,
        questions_answers=questions_answers,
        student_context=student_context,
    )

    response = client.models.generate_content(model=model, contents=full_prompt, config=config)
    json_response = response.text

    evaluation = GeminiLessonContext.model_validate_json(json_response)

    # Ensure arrays have same length (pad with empty strings if needed)
    state_array = evaluation.state if evaluation.state else []
    metacognition_array = evaluation.metacognition if evaluation.metacognition else []

    max_length = max(len(state_array), len(metacognition_array))
    state_array.extend([""] * (max_length - len(state_array)))
    metacognition_array.extend([""] * (max_length - len(metacognition_array)))

    return GeminiLessonContextResponse(
        state=state_array,
        metacognition=metacognition_array,
        ai_model=model,
    )

