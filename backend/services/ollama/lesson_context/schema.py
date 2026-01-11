from typing import List
from pydantic import BaseModel

class OllamaLessonContext(BaseModel):
    state: List[str] = []
    metacognition: List[str] = []

class OllamaLessonContextResponse(BaseModel):
    state: List[str]
    metacognition: List[str]
    ai_model: str
