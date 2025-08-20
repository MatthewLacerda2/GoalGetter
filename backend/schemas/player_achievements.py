from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import List

class PlayerAchievementItem(BaseModel):
    id: str
    name: str
    description: str
    image_url: str
    achieved_at: datetime
    
    model_config = ConfigDict(from_attributes=True)
    
class PlayerAchievementResponse(BaseModel):
    achievements: List[PlayerAchievementItem]
    
    model_config = ConfigDict(from_attributes=True)