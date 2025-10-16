import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Integer, ForeignKey
from sqlalchemy.orm import relationship
from backend.models.base import Base

class Student(Base):
    __tablename__ = "students"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, nullable=False, unique=True)
    google_id = Column(String, nullable=False, unique=True)
    goal_id = Column(String(36), ForeignKey("goals.id"), nullable=False)
    goal_name = Column(String, nullable=False)
    name = Column(String, nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    last_login = Column(DateTime, nullable=False, default=datetime.now())
    current_streak = Column(Integer, nullable=False, default=0)
    longest_streak = Column(Integer, nullable=False, default=0)
    current_objective_id = Column(String(36), ForeignKey("objectives.id"), nullable=False)
    current_objective_name = Column(String, nullable=False)
    overall_xp = Column(Integer, nullable=False, default=0)
    
    goal = relationship("Goal", back_populates="student", uselist=False)
    current_objective = relationship("Objective", back_populates="student", uselist=False)
    streak_days = relationship("StreakDay", back_populates="student", uselist=True)
    chat_messages = relationship("ChatMessage", back_populates="student")
    achievements = relationship("PlayerAchievement", back_populates="student")
    student_contexts = relationship("StudentContext", back_populates="student")