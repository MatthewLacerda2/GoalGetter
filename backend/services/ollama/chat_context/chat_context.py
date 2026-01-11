from typing import List, Optional
import ollama
from ollama._types import ResponseError
from backend.services.ollama.chat_context.prompt import get_chat_context_prompt
from backend.services.ollama.chat_context.schema import OllamaChatContext, OllamaChatContextResponse
from backend.models.chat_message import ChatMessage

def ollama_chat_context(
    goal_name: str,
    goal_description: str,
    objective_name: str,
    objective_description: str,
    messages: List[ChatMessage],
    student_context: Optional[List[str]] = None
) -> OllamaChatContextResponse:
    """
    Generate chat context using Ollama AI.
    
    Args:
        goal_name: Name of the student's goal
        goal_description: Description of the goal
        objective_name: Name of the current objective
        objective_description: Description of the current objective
        messages: List of chat messages between the student and chatbot
        student_context: Optional list of existing student context strings
    
    Returns:
        OllamaChatContextResponse with state[], metacognition[], and ai_model
    """
    model = "qwen3-vl:235b-cloud"
    full_prompt = get_chat_context_prompt(
        goal_name=goal_name,
        goal_description=goal_description,
        objective_name=objective_name,
        objective_description=objective_description,
        messages=messages,
        student_context=student_context
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
            format=OllamaChatContext.model_json_schema()
        )
        
        json_response = response.message.content
        
        evaluation = OllamaChatContext.model_validate_json(json_response)
        
        # Ensure arrays have same length (pad with empty strings if needed)
        state_array = evaluation.state if evaluation.state else []
        metacognition_array = evaluation.metacognition if evaluation.metacognition else []
        
        max_length = max(len(state_array), len(metacognition_array))
        state_array.extend([""] * (max_length - len(state_array)))
        metacognition_array.extend([""] * (max_length - len(metacognition_array)))
        
        return OllamaChatContextResponse(
            state=state_array,
            metacognition=metacognition_array,
            ai_model=model
        )
    except ResponseError as e:
        raise Exception(f"Ollama API error {e.status_code}: {str(e)}")
    except Exception as e:
        raise Exception(f"Unexpected error: {type(e).__name__}: {e}")
