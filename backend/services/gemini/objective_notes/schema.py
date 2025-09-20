from pydantic import BaseModel

class GeminiObjectiveNote(BaseModel):
    title: str
    info: str

class GeminiObjectiveNotesList(BaseModel):
    notes: list[GeminiObjectiveNote]