import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Integer, ForeignKey, CheckConstraint, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from backend.models.base import Base

class Student(Base):
    __tablename__ = "students"
    __table_args__ = (
        CheckConstraint('current_streak >= 0', name='check_current_streak_non_negative'),
        CheckConstraint('longest_streak >= 0', name='check_longest_streak_non_negative'),
        CheckConstraint('overall_xp >= 0', name='check_overall_xp_non_negative'),
        Index('idx_student_goal_id', 'goal_id'),
        Index('idx_student_current_objective_id', 'current_objective_id'),
    )

    id = Column(UUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, nullable=False, unique=True)
    google_id = Column(String, nullable=False, unique=True)
    goal_id = Column(UUID(as_uuid=False), ForeignKey("goals.id"), nullable=False)
    goal_name = Column(String, nullable=False)
    name = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    last_login = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    current_streak = Column(Integer, nullable=False, default=0)
    longest_streak = Column(Integer, nullable=False, default=0)
    current_objective_id = Column(UUID(as_uuid=False), ForeignKey("objectives.id"), nullable=False)
    current_objective_name = Column(String, nullable=False)
    overall_xp = Column(Integer, nullable=False, default=0)
    
    goal = relationship("Goal", back_populates="student", uselist=False)
    current_objective = relationship("Objective", back_populates="student", uselist=False)
    streak_days = relationship("StreakDay", back_populates="student", uselist=True)
    chat_messages = relationship("ChatMessage", back_populates="student")
    achievements = relationship("PlayerAchievement", back_populates="student")
    student_contexts = relationship("StudentContext", back_populates="student")
    multiple_choice_answers = relationship("MultipleChoiceAnswer", back_populates="student")
    subjective_answers = relationship("SubjectiveAnswer", back_populates="student")