import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector
from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base

class Goal(Base):
    __tablename__ = "goals"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    name = Column(String, nullable=True)
    description = Column(String, nullable=True)
    description_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    rating = Column(Integer, nullable=False, default=1200)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    
    student = relationship("Student", back_populates="goals")
    student_contexts = relationship("StudentContext", back_populates="goal", cascade="all, delete-orphan")
    lesson_questions = relationship("LessonQuestion", back_populates="goal", cascade="all, delete-orphan")
    onboarding_questions = relationship("OnboardingQuestion", back_populates="goal", cascade="all, delete-orphan")
    resources = relationship("Resource", back_populates="goal", cascade="all, delete-orphan")