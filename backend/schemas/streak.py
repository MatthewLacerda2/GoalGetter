from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import List

class StreakDayResponse(BaseModel):
    id: str
    date_time: datetime
    
    model_config = ConfigDict(from_attributes=True)

class TimePeriodStreak(BaseModel):
    current_streak: int
    streak_days: List[StreakDayResponse]