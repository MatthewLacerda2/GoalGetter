from typing import List
import ollama
from ollama._types import ResponseError
from backend.services.ollama.assessment.progress_evaluation.prompt import get_progress_evaluation_prompt
from backend.services.ollama.assessment.progress_evaluation.schema import OllamaProgressEvaluation, OllamaProgressEvaluationResponse
from backend.models.student_context import StudentContext

def ollama_progress_evaluation(
    goal_name: str,
    goal_description: str,
    objective_name: str,
    objective_description: str,
    percentage_completed: float,
    contexts: List[StudentContext]
) -> OllamaProgressEvaluationResponse:
    """
    Generate progress evaluation using Ollama AI.
    
    Args:
        goal_name: Name of the student's goal
        goal_description: Description of the goal
        objective_name: Name of the current objective
        objective_description: Description of the current objective
        percentage_completed: Current percentage completed for the objective
        contexts: List of student contexts (latest 8, ordered by objective then created_at)
    
    Returns:
        OllamaProgressEvaluationResponse with state[], metacognition[], percentage_completed, and ai_model
    """
    model = "gpt-oss:120b-cloud"
    full_prompt = get_progress_evaluation_prompt(
        goal_name=goal_name,
        goal_description=goal_description,
        objective_name=objective_name,
        objective_description=objective_description,
        percentage_completed=percentage_completed,
        contexts=contexts
    )

    try:
        response: ollama.ChatResponse = ollama.chat(
            model=model,
            stream=False,
            messages=[
                {
                    "role": "user",
                    "content": full_prompt
                }
            ],
            format=OllamaProgressEvaluation.model_json_schema()
        )
        
        json_response = response.message.content
        
        evaluation = OllamaProgressEvaluation.model_validate_json(json_response)
        
        # Ensure arrays have same length (pad with empty strings if needed)
        state_array = evaluation.state if evaluation.state else []
        metacognition_array = evaluation.metacognition if evaluation.metacognition else []
        
        max_length = max(len(state_array), len(metacognition_array))
        state_array.extend([""] * (max_length - len(state_array)))
        metacognition_array.extend([""] * (max_length - len(metacognition_array)))
        
        return OllamaProgressEvaluationResponse(
            state=state_array,
            metacognition=metacognition_array,
            percentage_completed=evaluation.percentage_completed,
            ai_model=model
        )
    except ResponseError as e:
        raise Exception(f"Ollama API error {e.status_code}: {str(e)}")
    except Exception as e:
        raise Exception(f"Unexpected error: {type(e).__name__}: {e}")
