import uuid
from sqlalchemy import Column, String, DateTime
from backend.models.base import Base
from datetime import datetime
from sqlalchemy.orm import relationship

class PlayerAchievement(Base):
    __tablename__ = "player_achievements"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    student_id = Column(String(36), nullable=False)
    achievement_id = Column(String(36), nullable=False)
    achieved_at = Column(DateTime, nullable=False, default=datetime.now())

    student = relationship("Student", back_populates="achievements")
    achievement = relationship("Achievement", back_populates="players")