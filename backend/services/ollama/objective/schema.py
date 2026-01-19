from pydantic import BaseModel

class OllamaObjective(BaseModel):
    name: str
    description: str
