import ollama
from ollama._types import ResponseError
from backend.services.ollama.student_context.schema import OllamaStudentContext
from backend.services.ollama.student_context.prompt import get_student_context_prompt

def ollama_generate_student_context(
    goal_name: str,
    goal_description: str,
    objective_name: str,
    objective_description: str,
    onboarding_prompt: str | None = None,
    questions_answers: list[tuple[str, str]] | None = None
) -> OllamaStudentContext:
    """
    Generate student context using Ollama AI.
    
    Args:
        goal_name: Name of the student's goal
        goal_description: Description of the goal
        objective_name: Name of the first objective
        objective_description: Description of the first objective
        onboarding_prompt: Optional initial prompt from the student
        questions_answers: Optional list of (question, answer) tuples from onboarding
    
    Returns:
        OllamaStudentContext with state and metacognition
    """
    model = "gpt-oss:120b-cloud"
    
    full_prompt = get_student_context_prompt(
        goal_name=goal_name,
        goal_description=goal_description,
        objective_name=objective_name,
        objective_description=objective_description,
        onboarding_prompt=onboarding_prompt,
        questions_answers=questions_answers
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
            format=OllamaStudentContext.model_json_schema()
        )
        
        json_response = response.message.content
        
        return OllamaStudentContext.model_validate_json(json_response)
    except ResponseError as e:
        raise Exception(f"Ollama API error {e.status_code}: {str(e)}")
    except Exception as e:
        raise Exception(f"Unexpected error: {type(e).__name__}: {e}")
