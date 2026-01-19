from typing import List

from pydantic import BaseModel


class GeminiChatContext(BaseModel):
    state: List[str] = []
    metacognition: List[str] = []


class GeminiChatContextResponse(BaseModel):
    state: List[str]
    metacognition: List[str]
    ai_model: str

