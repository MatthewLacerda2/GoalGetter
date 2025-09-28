from typing import List
from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.services.gemini.assessment.overall_evaluation.prompt import get_overall_review_prompt
from backend.services.gemini.assessment.overall_evaluation.schema import GeminiSubjectiveEvaluationReview

def gemini_subjective_evaluation_review(
    objective_name: str, objective_description: List[str], questions: List[str], answers: List[str]
) -> GeminiSubjectiveEvaluationReview:
    
    q_and_a = get_formatted_q_and_a(questions, answers)
    
    client = get_client()
    model = "gemini-2.5-flash"
    config = get_gemini_config(GeminiSubjectiveEvaluationReview.model_json_schema())
    full_prompt = get_overall_review_prompt(objective_name, objective_description, q_and_a)

    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    
    return GeminiSubjectiveEvaluationReview.model_validate_json(json_response)

def get_formatted_q_and_a(questions: List[str], answers: List[str]) -> str:
    
    return "\n".join([f"- {question}\nAnswer: {answer}" for (question, answer) in zip(questions, answers)])