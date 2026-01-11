from typing import List
from pydantic import BaseModel

class OllamaChatContext(BaseModel):
    state: List[str] = []
    metacognition: List[str] = []

class OllamaChatContextResponse(BaseModel):
    state: List[str]
    metacognition: List[str]
    ai_model: str
