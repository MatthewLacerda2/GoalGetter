import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector
from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base

class Goal(Base):
    __tablename__ = "goals"

    id = Column(UUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=True)
    description = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    description_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    
    student = relationship("Student", back_populates="goal", uselist=False)
    resources = relationship("Resource", back_populates="goal")
    objectives = relationship("Objective", back_populates="goal")
    student_contexts = relationship("StudentContext", back_populates="goal")
    achievements = relationship("Achievement", back_populates="goal")