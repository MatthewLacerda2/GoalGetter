from typing import List
from pydantic import BaseModel
import ollama
from ollama._types import ResponseError
from backend.services.ollama.assessment.prompt import generate_subjective_questions_prompt

class OllamaEvaluationQuestionsList(BaseModel):
    questions: List[str]

class OllamaEvaluationQuestionsResponse(BaseModel):
    questions: List[str]
    ai_model: str

def ollama_generate_subjective_questions(
    objective_name: str, objective_description: str, goal_name: str, num_questions: int
) -> OllamaEvaluationQuestionsResponse:
    
    model = "gpt-oss:120b-cloud"
    full_prompt = generate_subjective_questions_prompt(objective_name, objective_description, goal_name, num_questions)

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
            format=OllamaEvaluationQuestionsList.model_json_schema()
        )
        
        json_response = response.message.content
        
        questions_list = OllamaEvaluationQuestionsList.model_validate_json(json_response)
        return OllamaEvaluationQuestionsResponse(
            questions=questions_list.questions,
            ai_model=model
        )
    except ResponseError as e:
        raise Exception(f"Ollama API error {e.status_code}: {str(e)}")
    except Exception as e:
        raise Exception(f"Unexpected error: {type(e).__name__}: {e}")

if __name__ == "__main__":
    print(ollama_generate_subjective_questions(
        objective_name="Aprender Direitos e garantias",
        objective_description="Saber os direitos e garantias do acusado",
        goal_name="Aprender Direito Constitucional para concurso",
        num_questions=8
    ))
