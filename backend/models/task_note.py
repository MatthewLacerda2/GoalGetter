import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime
from pgvector.sqlalchemy import Vector
from sqlalchemy.orm import relationship

from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base

class TaskNote(Base):
    __tablename__ = "task_notes"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    task_id = Column(String(36), nullable=False)
    title = Column(String, nullable=True)
    notes = Column(String, nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    notes_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)

    task = relationship("Task", back_populates="notes")