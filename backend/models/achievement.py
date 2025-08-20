import uuid
from sqlalchemy import Column, String
from backend.models.base import Base
from sqlalchemy.orm import relationship

class Achievement(Base):
    __tablename__ = "achievements"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    description = Column(String, nullable=False)
    image_url = Column(String, nullable=False)
    
    players = relationship("PlayerAchievement", back_populates="achievement")