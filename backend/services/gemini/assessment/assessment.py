from typing import List
from pydantic import BaseModel
from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.services.gemini.assessment.prompt import generate_subjective_questions_prompt

class GeminiEvaluationQuestionsList(BaseModel):
    questions: List[str]

def gemini_generate_subjective_questions(
    objective_name: str, objective_description: str, goal_name: str, num_questions: int
) -> GeminiEvaluationQuestionsList:
    
    client = get_client()
    model = "gemini-2.5-flash"
    config = get_gemini_config(GeminiEvaluationQuestionsList.model_json_schema())
    full_prompt = generate_subjective_questions_prompt(objective_name, objective_description, goal_name, num_questions)

    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    
    return GeminiEvaluationQuestionsList.model_validate_json(json_response)

if __name__ == "__main__":
    print(gemini_generate_subjective_questions(
        objective_name="Do your first solo flight",
        objective_description="The ability to do a small solo Visual-Flight-Rules flight from take-off to landing with a small aircraft",
        goal_name="Do an international solo flight with a jet aifcraft",
        num_questions=8
    ))