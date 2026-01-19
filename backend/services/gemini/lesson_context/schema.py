from typing import List

from pydantic import BaseModel


class GeminiLessonContext(BaseModel):
    state: List[str] = []
    metacognition: List[str] = []


class GeminiLessonContextResponse(BaseModel):
    state: List[str]
    metacognition: List[str]
    ai_model: str

