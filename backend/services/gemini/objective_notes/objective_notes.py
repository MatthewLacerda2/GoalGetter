from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.services.gemini.objective_notes.schema import GeminiObjectiveNotesList, GeminiObjectiveNotesResponse
from backend.services.gemini.objective_notes.prompt import get_define_objective_notes_prompt

def gemini_define_objective_notes(
    objective_name: str, objective_description: str
) -> GeminiObjectiveNotesResponse:
    
    client = get_client()
    model = "gemini-2.5-flash-lite"
    config = get_gemini_config(GeminiObjectiveNotesList.model_json_schema())
    config.temperature = 1
    full_prompt = get_define_objective_notes_prompt(objective_name, objective_description)
    
    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    
    notes_list = GeminiObjectiveNotesList.model_validate_json(json_response)
    return GeminiObjectiveNotesResponse(
        notes=notes_list.notes,
        ai_model=model
    )

if __name__ == "__main__":
    print(gemini_define_objective_notes(
        objective_name="Write a simple Python script",
        objective_description="A simple python script that writes a simple response based on user input"
    ))