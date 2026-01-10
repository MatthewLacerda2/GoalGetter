import ollama
from ollama._types import ResponseError
from backend.services.ollama.chat.prompt import chat_system_prompt
from backend.services.ollama.chat.schema import StudentContextToChat, OllamaChatMessage, OllamaChatResponse

def ollama_messages_generator(
    messages: list[OllamaChatMessage], contexts: list[StudentContextToChat], objective_name: str, objective_description: str, goal_name: str
) -> OllamaChatResponse:
    
    model = "gpt-oss:120b-cloud"
    full_prompt = chat_system_prompt(objective_name, objective_description, goal_name, contexts)    
    messages.append(OllamaChatMessage(message=full_prompt, role="model", time="10:00:29"))
    
    ollama_messages = []
    for msg in messages:
        ollama_messages.append({
            "role": msg.role,
            "content": msg.message
        })

    try:
        response: ollama.ChatResponse = ollama.chat(
            model=model,
            stream=False,
            messages=ollama_messages,
            format=OllamaChatResponse.model_json_schema()
        )
        
        json_response = response.message.content
        
        return OllamaChatResponse.model_validate_json(json_response)
    except ResponseError as e:
        raise Exception(f"Ollama API error {e.status_code}: {str(e)}")
    except Exception as e:
        raise Exception(f"Unexpected error: {type(e).__name__}: {e}")
