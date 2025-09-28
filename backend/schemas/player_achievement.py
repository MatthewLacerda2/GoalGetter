from typing import List
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field

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

class LeaderboardItem(BaseModel):
    name: str
    objective: str
    xp: int = Field(..., description="Student's overall XP", ge=0)

class LeaderboardResponse(BaseModel):
    students: List[LeaderboardItem]