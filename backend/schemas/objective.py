from pydantic import BaseModel
from datetime import datetime

class ObjectiveNote(BaseModel):
    id: str
    title: str
    description: str
    created_at: datetime

class ObjectiveResponse(BaseModel):
    id: str
    name: str
    description: str
    percentage_completed: float
    created_at: datetime
    last_updated_at: datetime
    
    notes: list[ObjectiveNote]