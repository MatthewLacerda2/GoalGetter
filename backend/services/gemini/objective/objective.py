from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.services.gemini.objective.schema import GeminiObjective
from backend.services.gemini.objective.prompt import get_define_objective_prompt

def gemini_define_objective(
    goal_name: str, goal_description: str, latest_objective: str, latest_objective_description: str, student_context: list[str]
) -> GeminiObjective:
    
    client = get_client()
    model = "gemini-2.5-flash-lite"
    config = get_gemini_config(GeminiObjective.model_json_schema())
    full_prompt = get_define_objective_prompt(goal_name, goal_description, latest_objective, latest_objective_description, student_context)
    
    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    
    return GeminiObjective.model_validate_json(json_response)

if __name__ == "__main__":
    print(gemini_define_objective(
        goal_name="Create a Python API for data analysis",
        goal_description="Mastery of Python, being able to create a big Python program that analyses large amounts of data throughly, with strong good practices",
        latest_objective="Write a simple Python script",
        latest_objective_description="A simple python script that writes a simple response based on user input",
        student_context=["The student seems to only advance after building a strong foundation", "The student is an enthusiastic learner", "The student likes to experiment a lot"]
    ))