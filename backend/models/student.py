import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Integer, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from backend.models.base import Base

class Student(Base):
    __tablename__ = "students"
    __table_args__ = (
        CheckConstraint('current_streak >= 0', name='check_current_streak_non_negative'),
        CheckConstraint('longest_streak >= 0', name='check_longest_streak_non_negative'),
        CheckConstraint('overall_xp >= 0', name='check_overall_xp_non_negative'),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, nullable=False, unique=True)
    google_id = Column(String, nullable=False, unique=True)
    name = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    last_login = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    current_streak = Column(Integer, nullable=False, default=0)
    longest_streak = Column(Integer, nullable=False, default=0)
    overall_xp = Column(Integer, nullable=False, default=0)
    
    goals = relationship("Goal", back_populates="student", cascade="all, delete-orphan")
    chat_messages = relationship("ChatMessage", back_populates="student", cascade="all, delete-orphan")
    student_contexts = relationship("StudentContext", back_populates="student", cascade="all, delete-orphan")
    lesson_answers = relationship("LessonAnswer", back_populates="student", cascade="all, delete-orphan")
    onboarding_answers = relationship("OnboardingAnswer", back_populates="student", cascade="all, delete-orphan")