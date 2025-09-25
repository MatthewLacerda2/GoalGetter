from typing import List
from datetime import datetime
from pydantic import BaseModel, ConfigDict

class StreakDayResponse(BaseModel):
    id: str
    date_time: datetime
    
    model_config = ConfigDict(from_attributes=True)

class TimePeriodStreak(BaseModel):
    current_streak: int
    streak_days: List[StreakDayResponse]

class XpDay(BaseModel):
    id: str
    xp: int
    date_time: datetime
    
    model_config = ConfigDict(from_attributes=True)

class XpByDaysResponse(BaseModel):
    days: List[XpDay]