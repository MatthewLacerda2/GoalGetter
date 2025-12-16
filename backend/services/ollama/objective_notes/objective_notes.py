import ollama
from ollama._types import ResponseError
from backend.services.ollama.objective_notes.schema import OllamaObjectiveNotesList
from backend.services.ollama.objective_notes.prompt import get_define_objective_notes_prompt

def ollama_define_objective_notes(
    objective_name: str, objective_description: str
) -> OllamaObjectiveNotesList:
    
    model = "gpt-oss:120b-cloud"
    full_prompt = get_define_objective_notes_prompt(objective_name, objective_description)
    
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
            format=OllamaObjectiveNotesList.model_json_schema()
        )
        
        json_response = response.message.content
        
        return OllamaObjectiveNotesList.model_validate_json(json_response)
    except ResponseError as e:
        raise Exception(f"Ollama API error {e.status_code}: {str(e)}")
    except Exception as e:
        raise Exception(f"Unexpected error: {type(e).__name__}: {e}")

if __name__ == "__main__":
    print(ollama_define_objective_notes(
        objective_name="Write a simple Python script",
        objective_description="A simple python script that writes a simple response based on user input"
    ))
