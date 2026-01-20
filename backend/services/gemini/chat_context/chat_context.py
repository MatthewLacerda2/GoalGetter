from typing import List, Optional

from backend.models.chat_message import ChatMessage
from backend.services.gemini.chat_context.prompt import get_chat_context_prompt
from backend.services.gemini.chat_context.schema import (
    GeminiChatContext,
    GeminiChatContextResponse,
)
from backend.utils.gemini.gemini_configs import get_client, get_gemini_config


def gemini_chat_context(
    goal_name: str,
    goal_description: str,
    objective_name: str,
    objective_description: str,
    messages: List[ChatMessage],
    student_context: Optional[List[str]] = None,
) -> GeminiChatContextResponse:
    """
    Generate chat context using Gemini AI.

    Args:
        goal_name: Name of the student's goal
        goal_description: Description of the goal
        objective_name: Name of the current objective
        objective_description: Description of the current objective
        messages: List of chat messages between the student and chatbot
        student_context: Optional list of existing student context strings

    Returns:
        GeminiChatContextResponse with state[], metacognition[], and ai_model
    """
    client = get_client()
    model = "gemini-2.5-flash-lite"
    config = get_gemini_config(GeminiChatContext.model_json_schema())

    full_prompt = get_chat_context_prompt(
        goal_name=goal_name,
        goal_description=goal_description,
        objective_name=objective_name,
        objective_description=objective_description,
        messages=messages,
        student_context=student_context,
    )

    response = client.models.generate_content(model=model, contents=full_prompt, config=config)
    json_response = response.text

    return GeminiChatContextResponse.model_validate_json(json_response)
