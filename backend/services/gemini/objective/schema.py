from pydantic import BaseModel

class GeminiObjective(BaseModel):
    name: str
    description: str