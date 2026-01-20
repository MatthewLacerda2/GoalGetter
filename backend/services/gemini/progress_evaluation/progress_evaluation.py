from typing import List

from backend.models.student_context import StudentContext
from backend.services.gemini.progress_evaluation.prompt import get_progress_evaluation_prompt
from backend.services.gemini.progress_evaluation.schema import (
    GeminiProgressEvaluation,
    GeminiProgressEvaluationResponse,
)
from backend.utils.gemini.gemini_configs import get_client, get_gemini_config


def gemini_progress_evaluation(
    goal_name: str,
    goal_description: str,
    objective_name: str,
    objective_description: str,
    percentage_completed: float,
    contexts: List[StudentContext],
) -> GeminiProgressEvaluationResponse:
    """
    Generate progress evaluation using Gemini AI.

    Args:
        goal_name: Name of the student's goal
        goal_description: Description of the goal
        objective_name: Name of the current objective
        objective_description: Description of the current objective
        percentage_completed: Current percentage completed for the objective
        contexts: List of student contexts (latest 8, ordered by objective then created_at)

    Returns:
        GeminiProgressEvaluationResponse with state[], metacognition[], percentage_completed, and ai_model
    """
    client = get_client()
    model = "gemini-3-pro-preview"
    config = get_gemini_config(GeminiProgressEvaluation.model_json_schema())

    full_prompt = get_progress_evaluation_prompt(
        goal_name=goal_name,
        goal_description=goal_description,
        objective_name=objective_name,
        objective_description=objective_description,
        percentage_completed=percentage_completed,
        contexts=contexts,
    )

    response = client.models.generate_content(model=model, contents=full_prompt, config=config)
    json_response = response.text

    evaluation = GeminiProgressEvaluation.model_validate_json(json_response)

    # Ensure arrays have same length (pad with empty strings if needed)
    state_array = evaluation.state if evaluation.state else []
    metacognition_array = evaluation.metacognition if evaluation.metacognition else []

    max_length = max(len(state_array), len(metacognition_array))
    state_array.extend([""] * (max_length - len(state_array)))
    metacognition_array.extend([""] * (max_length - len(metacognition_array)))

    return GeminiProgressEvaluationResponse(
        state=state_array,
        metacognition=metacognition_array,
        percentage_completed=evaluation.percentage_completed,
        ai_model=model,
    )

