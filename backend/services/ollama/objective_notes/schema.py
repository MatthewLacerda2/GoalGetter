from pydantic import BaseModel

class OllamaObjectiveNote(BaseModel):
    title: str
    info: str

class OllamaObjectiveNotesList(BaseModel):
    notes: list[OllamaObjectiveNote]

class OllamaObjectiveNotesResponse(BaseModel):
    notes: list[OllamaObjectiveNote]
    ai_model: str