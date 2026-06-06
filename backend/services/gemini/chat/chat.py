from google.genai.types import GenerateContentResponse
from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.services.gemini.chat.prompt import chat_system_prompt
from backend.services.gemini.chat.schema import StudentContextToChat, GeminiChatMessage, GeminiChatResponse
from backend.utils.envs import GEMINI_FAST_MODEL

def gemini_messages_generator(
    messages: list[GeminiChatMessage], 
    contexts: list[StudentContextToChat], 
    goal_name: str,
    goal_description: str
) -> GeminiChatResponse:
    client = get_client()
    model = GEMINI_FAST_MODEL
    config = get_gemini_config(GeminiChatResponse.model_json_schema())
    
    # Generate system prompt
    system_instruction = chat_system_prompt(goal_name, goal_description, contexts)    
    
    gemini_messages = [
        {
            "role": "user",
            "parts": [{"text": system_instruction}]
        }
    ]
    
    for msg in messages:
        role = msg.role if msg.role == "user" else "model"
        gemini_messages.append({
            "role": role,
            "parts": [{"text": msg.message}]
        })

    response: GenerateContentResponse = client.models.generate_content(
        model=model, contents=gemini_messages, config=config
    )
    
    json_response = response.text
    return GeminiChatResponse.model_validate_json(json_response)