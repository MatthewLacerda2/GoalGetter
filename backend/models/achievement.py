import uuid
from sqlalchemy import Column, String, ForeignKey
from backend.models.base import Base
from sqlalchemy.orm import relationship

class Achievement(Base):
    __tablename__ = "achievements"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    description = Column(String, nullable=False)
    image_url = Column(String, nullable=False)
    goal_id = Column(String(36), ForeignKey("goals.id"), nullable=True)
    
    players = relationship("PlayerAchievement", back_populates="achievement")
    goal = relationship("Goal", back_populates="achievements")