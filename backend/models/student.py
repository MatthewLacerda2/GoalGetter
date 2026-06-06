import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Integer, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from backend.models.base import Base

class Student(Base):
    __tablename__ = "students"
    __table_args__ = (
        CheckConstraint('progress_rating >= 0', name='check_progress_rating_non_negative'),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, nullable=False, unique=True)
    google_id = Column(String, nullable=False, unique=True)
    name = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    last_login = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    progress_rating = Column(Integer, nullable=False, default=1200)
    
    goals = relationship("Goal", back_populates="student", cascade="all, delete-orphan")
    chat_messages = relationship("ChatMessage", back_populates="student", cascade="all, delete-orphan")
    student_contexts = relationship("StudentContext", back_populates="student", cascade="all, delete-orphan")
    refresh_tokens = relationship("RefreshToken", back_populates="student", cascade="all, delete-orphan")