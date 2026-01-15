import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, Boolean, Index
from sqlalchemy.dialects.postgresql import UUID
from backend.models.base import Base
from datetime import datetime
from sqlalchemy.orm import relationship

class PlayerAchievement(Base):
    __tablename__ = "player_achievements"
    __table_args__ = (
        Index('idx_player_achievement_student_id', 'student_id'),
        Index('idx_player_achievement_achievement_id', 'achievement_id'),
        Index('idx_player_achievement_goal_id', 'goal_id'),
    )
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id"), nullable=False)
    achievement_id = Column(UUID(as_uuid=True), ForeignKey("achievements.id"), nullable=False)
    goal_id = Column(UUID(as_uuid=True), ForeignKey("goals.id"), nullable=False)
    is_student_achievement = Column(Boolean, nullable=False, default=False)
    achieved_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)

    student = relationship("Student", back_populates="achievements")
    achievement = relationship("Achievement", back_populates="players")
    goal = relationship("Goal", back_populates="player_achievements")