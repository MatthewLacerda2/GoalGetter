import ollama
from ollama._types import ResponseError
from backend.services.ollama.activity.schema import OllamaMultipleChoiceQuestionsList
from backend.services.ollama.activity.prompt import generate_multiple_choice_questions_prompt

def ollama_generate_multiple_choice_questions(
    objective_name: str, objective_description: str, previous_objectives: list[str], informations: list[str], num_questions: int
) -> OllamaMultipleChoiceQuestionsList:
    
    model: str = "gpt-oss:120b-cloud"
    full_prompt = generate_multiple_choice_questions_prompt(objective_name, objective_description, previous_objectives, informations, num_questions)

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
            format=OllamaMultipleChoiceQuestionsList.model_json_schema()
        )
        
        json_response = response.message.content
        
        return OllamaMultipleChoiceQuestionsList.model_validate_json(json_response)
    except ResponseError as e:
        raise Exception(f"Ollama API error {e.status_code}: {str(e)}")
    except Exception as e:
        raise Exception(f"Unexpected error: {type(e).__name__}: {e}")

if __name__ == "__main__":
    print(ollama_generate_multiple_choice_questions(
        objective_name="Aprender Direitos e garantias",
        objective_description="Saber os direitos e garantias do acusado",
        previous_objectives=[],
        informations=["O estudante está se preparando para um concurso de tecnico judiciário"],
        num_questions=6
    ))
