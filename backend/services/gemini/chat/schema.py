from pydantic import BaseModel

class GeminiChatResponse(BaseModel):
    messages: list[str]

class ChatMessageWithGemini(BaseModel):
    message: str
    role: str
    time: str

class StudentContextToChat(BaseModel):
    state: str | None = None
    metacognition: str | None = None