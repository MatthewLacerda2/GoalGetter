from pydantic import BaseModel

class GeminiLearnInfo(BaseModel):
    title: str
    theme: str
    content: str