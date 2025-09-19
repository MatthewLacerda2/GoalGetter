from backend.utils.gemini.activity.schema import GeminiMultipleChoiceQuestionsList
from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.utils.gemini.activity.prompt import generate_multiple_choice_questions_prompt

def gemini_generate_multiple_choice_questions(
    objective_name: str, objective_description: str, previous_objectives: list[str], informations: list[str], num_questions: int
) -> GeminiMultipleChoiceQuestionsList:
    
    client = get_client()
    model = "gemini-2.5-flash"
    config = get_gemini_config(GeminiMultipleChoiceQuestionsList.model_json_schema())
    config.temperature = 2
    full_prompt = generate_multiple_choice_questions_prompt(objective_name, objective_description, previous_objectives, informations, num_questions)

    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    
    return GeminiMultipleChoiceQuestionsList.model_validate_json(json_response)

if __name__ == "__main__":
    print(gemini_generate_multiple_choice_questions(
        objective_name="Write a simple Python script",
        objective_description="A simple python script that writes a simple response based on user input",
        previous_objectives=["Write and run a Hello World", "Learn the main keywords of Python", "Declare and use variables"],
        informations=["The student seems to only advance after building a strong foundation", "The student is an enthusiastic learner", "The student likes to experiment a lot"],
        num_questions=8
    ))