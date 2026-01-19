from google.genai.types import GenerateContentResponse
from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.services.gemini.chat.prompt import chat_system_prompt
from backend.services.gemini.chat.schema import StudentContextToChat, GeminiChatMessage, GeminiChatResponse

def gemini_messages_generator(
    messages: list[GeminiChatMessage], contexts: list[StudentContextToChat], objective_name: str, objective_description: str, goal_name: str
) -> GeminiChatResponse:
    
    client = get_client()
    model = "gemini-2.5-flash-lite"
    config = get_gemini_config(GeminiChatResponse.model_json_schema())
    config.temperature = 1
    full_prompt = chat_system_prompt(objective_name, objective_description, goal_name, contexts)    
    messages.append(GeminiChatMessage(message=full_prompt, role="user", time="10:00:29"))
    
    gemini_messages = []
    for msg in messages:
        # Gemini only accepts 'user' and 'model' as roles
        # Map any non-user role (like 'assistant') to 'model'
        role = msg.role if msg.role == "user" else "model"
        gemini_messages.append({
            "role": role,
            "parts": [{"text": msg.message}]
        })
    
    print("--------------------------------")
    print(gemini_messages)
    print("--------------------------------")

    response: GenerateContentResponse = client.models.generate_content(
        model=model, contents=gemini_messages, config=config
    )
    
    #print("Total tokens:", response.usage_metadata.total_token_count)
    #print("Total tokens:", response.usage_metadata.prompt_token_count)
    #print("Total tokens:", response.usage_metadata.candidates_token_count)
    
    json_response = response.text
    
    return GeminiChatResponse.model_validate_json(json_response)