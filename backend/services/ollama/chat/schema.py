from pydantic import BaseModel

class OllamaChatResponse(BaseModel):
    messages: list[str]

class OllamaChatMessage(BaseModel):
    message: str
    role: str
    time: str

class StudentContextToChat(BaseModel):
    state: str | None = None
    metacognition: str | None = None
