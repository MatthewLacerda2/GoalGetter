from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.services.gemini.learn_info.schema import GeminiLearnInfo
from backend.services.gemini.learn_info.prompt import get_generate_learn_info_prompt

def gemini_define_learn_info(
    objective_name: str, objective_description: str, informations: list[str]
) -> GeminiLearnInfo:
    
    client = get_client()
    model = "gemini-2.5-flash"
    config = get_gemini_config(GeminiLearnInfo.model_json_schema())
    config.temperature = 2
    full_prompt = get_generate_learn_info_prompt(objective_name, objective_description, informations)
    
    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    
    return GeminiLearnInfo.model_validate_json(json_response)

if __name__ == "__main__":
    print(gemini_define_learn_info(
        objective_name="Write a simple Python script",
        objective_description="A simple python script that writes a simple response based on user input",
        informations=["The student seems to only advance after building a strong foundation", "The student is an enthusiastic learner", "The student likes to experiment a lot"]
    ))