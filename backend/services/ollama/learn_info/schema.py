from pydantic import BaseModel

class OllamaLearnInfo(BaseModel):
    title: str
    theme: str
    content: str
