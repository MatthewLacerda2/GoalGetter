from pydantic import BaseModel

class GeminiObjectiveNote(BaseModel):
    title: str
    info: str

class GeminiObjectiveNotesList(BaseModel):
    notes: list[GeminiObjectiveNote]

class GeminiObjectiveNotesResponse(BaseModel):
    notes: list[GeminiObjectiveNote]
    ai_model: str