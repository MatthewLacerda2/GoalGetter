import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector

from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base

class Goal(Base):
    __tablename__ = "goals"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    curated_course_id = Column(String(36), ForeignKey("curated_courses.id"), nullable=True)
    name = Column(String, nullable=False)
    description = Column(String, nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    description_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    
    student = relationship("Student", back_populates="goal", uselist=False)
    resources = relationship("Resource", back_populates="goal")
    objectives = relationship("Objective", back_populates="goal")
    student_contexts = relationship("StudentContext", back_populates="goal")
    achievements = relationship("Achievement", back_populates="goal")
    curated_course = relationship("CuratedCourse", back_populates="goal")