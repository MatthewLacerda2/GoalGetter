import uuid
from datetime import datetime
from sqlalchemy.orm import relationship
from sqlalchemy import Boolean, Column, String, DateTime, ForeignKey
from pgvector.sqlalchemy import Vector
from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base

class ObjectiveNote(Base):
    __tablename__ = "objective_notes"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    objective_id = Column(String(36), ForeignKey("objectives.id"), nullable=False)
    title = Column(String, nullable=False)
    info = Column(String, nullable=False)
    info_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    is_favorited = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    ai_model = Column(String, nullable=False)

    objective = relationship("Objective", back_populates="notes")