import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID
from backend.models.base import Base
from datetime import datetime
from sqlalchemy.orm import relationship

class PlayerAchievement(Base):
    __tablename__ = "player_achievements"
    __table_args__ = (
        Index('idx_player_achievement_student_id', 'student_id'),
        Index('idx_player_achievement_achievement_id', 'achievement_id'),
    )
    
    id = Column(UUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4()))
    student_id = Column(UUID(as_uuid=False), ForeignKey("students.id"), nullable=False)
    #Consider including a goal
    achievement_id = Column(UUID(as_uuid=False), ForeignKey("achievements.id"), nullable=False)
    achieved_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)

    student = relationship("Student", back_populates="achievements")
    achievement = relationship("Achievement", back_populates="players")