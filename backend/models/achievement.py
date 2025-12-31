import uuid
from sqlalchemy import Column, String, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID
from backend.models.base import Base
from sqlalchemy.orm import relationship

class Achievement(Base):
    __tablename__ = "achievements"
    __table_args__ = (
        Index('idx_achievement_goal_id', 'goal_id'),
    )

    id = Column(UUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    description = Column(String, nullable=False)
    image_url = Column(String, nullable=False)
    goal_id = Column(UUID(as_uuid=False), ForeignKey("goals.id"), nullable=True)
    
    players = relationship("PlayerAchievement", back_populates="achievement")
    goal = relationship("Goal", back_populates="achievements")