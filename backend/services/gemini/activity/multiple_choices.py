from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.services.gemini.activity.schema import GeminiMultipleChoiceQuestionsList, GeminiMultipleChoiceQuestionsResponse
from backend.services.gemini.activity.prompt import generate_multiple_choice_questions_prompt

def gemini_generate_multiple_choice_questions(
    objective_name: str, objective_description: str, previous_objectives: list[str], informations: list[str], num_questions: int
) -> GeminiMultipleChoiceQuestionsResponse:
    
    client = get_client()
    model = "gemini-3-flash-preview"
    config = get_gemini_config(GeminiMultipleChoiceQuestionsList.model_json_schema())
    full_prompt = generate_multiple_choice_questions_prompt(objective_name, objective_description, previous_objectives, informations, num_questions)

    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    
    questions_list = GeminiMultipleChoiceQuestionsList.model_validate_json(json_response)
    return GeminiMultipleChoiceQuestionsResponse(
        questions=questions_list.questions,
        ai_model=model
    )

if __name__ == "__main__":
    print(gemini_generate_multiple_choice_questions(
        objective_name="Aprender Direitos e garantias",
        objective_description="Saber os direitos e garantias do acusado",
        previous_objectives=[],
        informations=["O estudante está se preparando para um concurso de tecnico judiciário"],
        num_questions=6
    ))