import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector
from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base

class Goal(Base):
    __tablename__ = "goals"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=True)
    description = Column(String, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    description_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    #TODO: latest objective id
    
    student = relationship("Student", back_populates="goal", uselist=False)
    resources = relationship("Resource", back_populates="goal")
    objectives = relationship("Objective", back_populates="goal")
    student_contexts = relationship("StudentContext", back_populates="goal")
    achievements = relationship("Achievement", back_populates="goal")