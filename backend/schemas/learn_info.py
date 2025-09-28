from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field

class LearnInfo(BaseModel):
    id: str
    objective_id: str
    title: str
    theme: str
    text: str = Field(..., description="Microlearning content. Written in markdown")
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)
