from datetime import datetime
from typing import List
from pydantic import BaseModel, ConfigDict

class StudentContextItem(BaseModel):
    id: str
    created_at: datetime
    state: str
    metacognition: str
    
    model_config = ConfigDict(from_attributes=True)

class StudentContextResponse(BaseModel):
    contexts: List[StudentContextItem]
    
    model_config = ConfigDict(from_attributes=True)

class CreateStudentContextRequest(BaseModel):
    context: str
    
    model_config = ConfigDict(from_attributes=True)
