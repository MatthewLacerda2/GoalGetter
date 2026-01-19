import ollama
from ollama._types import ResponseError
from backend.services.ollama.learn_info.schema import OllamaLearnInfo
from backend.services.ollama.learn_info.prompt import get_generate_learn_info_prompt

def ollama_define_learn_info(
    objective_name: str, objective_description: str, informations: list[str]
) -> OllamaLearnInfo:
    
    model = "gpt-oss:120b-cloud"
    full_prompt = get_generate_learn_info_prompt(objective_name, objective_description, informations)
    
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
            format=OllamaLearnInfo.model_json_schema()
        )
        
        json_response = response.message.content
        
        return OllamaLearnInfo.model_validate_json(json_response)
    except ResponseError as e:
        raise Exception(f"Ollama API error {e.status_code}: {str(e)}")
    except Exception as e:
        raise Exception(f"Unexpected error: {type(e).__name__}: {e}")

if __name__ == "__main__":
    print(ollama_define_learn_info(
        objective_name="Write a simple Python script",
        objective_description="A simple python script that writes a simple response based on user input",
        informations=["The student seems to only advance after building a strong foundation", "The student is an enthusiastic learner", "The student likes to experiment a lot"]
    ))
