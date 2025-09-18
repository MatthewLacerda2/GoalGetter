from pydantic import BaseModel, ConfigDict
from datetime import datetime

class ObjectiveNote(BaseModel):
    id: str
    title: str
    info: str
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)

class ObjectiveResponse(BaseModel):
    id: str
    name: str
    description: str
    percentage_completed: float
    created_at: datetime
    last_updated_at: datetime
    
    notes: list[ObjectiveNote]
    
    model_config = ConfigDict(from_attributes=True)