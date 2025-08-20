import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey
from backend.models.base import Base
from datetime import datetime
from sqlalchemy.orm import relationship

class PlayerAchievement(Base):
    __tablename__ = "player_achievements"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    student_id = Column(String(36), ForeignKey("students.id"), nullable=False)
    #Consider including a goal
    achievement_id = Column(String(36), ForeignKey("achievements.id"), nullable=False)
    achieved_at = Column(DateTime, nullable=False, default=datetime.now())

    student = relationship("Student", back_populates="achievements")
    achievement = relationship("Achievement", back_populates="players")