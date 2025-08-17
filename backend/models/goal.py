import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector

from backend.models.base import Base

class Goal(Base):
    __tablename__ = "goals"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    description = Column(String, nullable=False)
    description_embedding = Column(Vector(3072), nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    student_id = Column(String(36), nullable=False)
    
    student = relationship("Student", back_populates="goals")
    resources = relationship("Resource", back_populates="goal")
    objectives = relationship("Objective", back_populates="goal")
    student_contexts = relationship("StudentContext", back_populates="goal")