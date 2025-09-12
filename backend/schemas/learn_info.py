from pydantic import BaseModel, ConfigDict
from datetime import datetime

class LearnInfo(BaseModel):
    id: str
    objective_id: str
    learn_info_title: str
    learn_info: list[str]
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)
