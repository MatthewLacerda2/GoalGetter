import uuid

from pgvector.sqlalchemy import Vector
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from backend.core import clock
from backend.models.base import Base
from backend.utils.envs import NUM_DIMENSIONS


class Goal(Base):
    __tablename__ = "goals"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id = Column(
        UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False
    )
    name = Column(String, nullable=True)
    description = Column(String, nullable=True)
    description_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    rating = Column(Integer, nullable=False, default=1200)
    created_at = Column(DateTime(timezone=True), nullable=False, default=clock.now)
    # onupdate: any change to the row (the rating after a lesson, too) moves it, so
    # the goals list can read it as "last studied".
    updated_at = Column(
        DateTime(timezone=True), nullable=False, default=clock.now, onupdate=clock.now
    )

    student = relationship("Student", back_populates="goals", foreign_keys=[student_id])
    student_contexts = relationship(
        "StudentContext", back_populates="goal", cascade="all, delete-orphan"
    )
    lesson_questions = relationship(
        "LessonQuestion", back_populates="goal", cascade="all, delete-orphan"
    )
    onboarding_questions = relationship(
        "OnboardingQuestion", back_populates="goal", cascade="all, delete-orphan"
    )
    resources = relationship("Resource", back_populates="goal", cascade="all, delete-orphan")
    microlearning_contents = relationship(
        "MicrolearningContent", back_populates="goal", cascade="all, delete-orphan"
    )
