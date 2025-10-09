from backend.services.gemini.activity.schema import GeminiMultipleChoiceQuestionsList
from backend.services.gemini.activity.prompt import generate_multiple_choice_questions_prompt
import ollama

def ollama_generate_multiple_choice_questions(
    objective_name: str, objective_description: str, previous_objectives: list[str], informations: list[str], num_questions: int
) -> GeminiMultipleChoiceQuestionsList:
    
    model: str = "gemma3:4b"
    full_prompt = generate_multiple_choice_questions_prompt(objective_name, objective_description, previous_objectives, informations, num_questions)

    response: ollama.ChatResponse = ollama.chat(
        model=model,
        stream=False,
        messages=[
            {
                "role": "user",
                "content": full_prompt
            }
        ],
        format=GeminiMultipleChoiceQuestionsList.model_json_schema()
    )
    
    return response

if __name__ == "__main__":
    print(ollama_generate_multiple_choice_questions(
        objective_name="Aprender Direitos e garantias",
        objective_description="Saber os direitos e garantias do acusado",
        previous_objectives=[],
        informations=["O estudante está se preparando para um concurso de tecnico judiciário"],
        num_questions=6
    ))