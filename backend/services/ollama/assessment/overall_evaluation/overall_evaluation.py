from typing import List
import ollama
from ollama._types import ResponseError
from backend.services.ollama.assessment.overall_evaluation.prompt import get_overall_review_prompt
from backend.services.ollama.assessment.overall_evaluation.schema import OllamaSubjectiveEvaluationReview

def ollama_subjective_evaluation_review(
    objective_name: str, objective_description: str, questions: List[str], answers: List[str]
) -> OllamaSubjectiveEvaluationReview:
    
    q_and_a = get_formatted_q_and_a(questions, answers)
    
    model = "gpt-oss:120b-cloud"
    full_prompt = get_overall_review_prompt(objective_name, objective_description, q_and_a)

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
            format=OllamaSubjectiveEvaluationReview.model_json_schema()
        )
        
        json_response = response.message.content
        
        return OllamaSubjectiveEvaluationReview.model_validate_json(json_response)
    except ResponseError as e:
        raise Exception(f"Ollama API error {e.status_code}: {str(e)}")
    except Exception as e:
        raise Exception(f"Unexpected error: {type(e).__name__}: {e}")

def get_formatted_q_and_a(questions: List[str], answers: List[str]) -> str:
    
    return "\n".join([f"- {question}\nAnswer: {answer}" for (question, answer) in zip(questions, answers)])
