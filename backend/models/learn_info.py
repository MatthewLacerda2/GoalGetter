from sqlalchemy import Column, String, ForeignKey, JSON, DateTime
import uuid
from datetime import datetime
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector
from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base

class LearnInfo(Base):
    __tablename__ = "learn_infos"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    objective_id = Column(String(36), ForeignKey("objectives.id"), nullable=False)
    learn_info_title = Column(String, nullable=False)
    learn_info = Column(JSON, nullable=False)
    learn_info_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    
    objective = relationship("Objective", back_populates="learn_infos")