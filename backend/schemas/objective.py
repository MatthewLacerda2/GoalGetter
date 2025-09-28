from typing import List
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field

class ObjectiveNote(BaseModel):
    id: str
    title: str
    info: str
    is_favorited: bool
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)

class ObjectiveResponse(BaseModel):
    id: str
    name: str
    description: str
    percentage_completed: float = Field(..., description="How much mastery of the objective does the student have?", ge=0, le=100)
    created_at: datetime
    last_updated_at: datetime
    
    notes: list[ObjectiveNote]
    
    model_config = ConfigDict(from_attributes=True)

class ObjectiveItem(BaseModel):
    id: str
    name: str
    description: str
    percentage_completed: int
    created_at: datetime
    last_updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)

class ObjectiveListResponse(BaseModel):
    objective_list: List[ObjectiveItem]

class ObjectiveNoteLikeResponse(BaseModel):
    message_id: str
    is_favorited: bool
    
    model_config = ConfigDict(from_attributes=True)