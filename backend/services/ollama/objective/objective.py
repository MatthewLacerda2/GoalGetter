import ollama
from ollama._types import ResponseError
from backend.services.ollama.objective.schema import OllamaObjective
from backend.services.ollama.objective.prompt import get_define_objective_prompt

def ollama_define_objective(
    goal_name: str, goal_description: str, latest_objective: str, latest_objective_description: str, student_context: list[str]
) -> OllamaObjective:
    
    model = "gpt-oss:120b-cloud"
    full_prompt = get_define_objective_prompt(goal_name, goal_description, latest_objective, latest_objective_description, student_context)
    
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
            format=OllamaObjective.model_json_schema()
        )
        
        json_response = response.message.content
        
        return OllamaObjective.model_validate_json(json_response)
    except ResponseError as e:
        raise Exception(f"Ollama API error {e.status_code}: {str(e)}")
    except Exception as e:
        raise Exception(f"Unexpected error: {type(e).__name__}: {e}")

if __name__ == "__main__":
    print(ollama_define_objective(
        goal_name="Create a Python API for data analysis",
        goal_description="Mastery of Python, being able to create a big Python program that analyses large amounts of data throughly, with strong good practices",
        latest_objective="Write a simple Python script",
        latest_objective_description="A simple python script that writes a simple response based on user input",
        student_context=["The student seems to only advance after building a strong foundation", "The student is an enthusiastic learner", "The student likes to experiment a lot"]
    ))
