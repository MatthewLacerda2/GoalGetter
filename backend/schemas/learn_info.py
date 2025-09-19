from pydantic import BaseModel, ConfigDict
from datetime import datetime

class LearnInfo(BaseModel):
    id: str
    objective_id: str
    title: str
    theme: str
    text: str
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)
