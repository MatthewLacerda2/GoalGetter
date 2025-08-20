from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import List

class StreakDay(BaseModel):
    id: str
    date_time: datetime
    
    model_config = ConfigDict(from_attributes=True)

class WeekStreak(BaseModel):
    current_streak: int
    streak_days: List[StreakDay]