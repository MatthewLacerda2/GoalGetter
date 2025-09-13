import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Integer, ForeignKey
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector

from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base

class Student(Base):
    __tablename__ = "students"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, nullable=False, unique=True)
    google_id = Column(String, nullable=False, unique=True)
    goal_id = Column(String(36), ForeignKey("goals.id"), nullable=True, default=None)
    goal_name = Column(String, nullable=True, default=None)
    name = Column(String, nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    last_login = Column(DateTime, nullable=False, default=datetime.now())
    current_streak = Column(Integer, nullable=False, default=0)
    longest_streak = Column(Integer, nullable=False, default=0)
    overall_xp = Column(Integer, nullable=False, default=0)
    
    goal = relationship("Goal", back_populates="student", uselist=False)
    streak_days = relationship("StreakDay", back_populates="student", uselist=False)
    chat_messages = relationship("ChatMessage", back_populates="student")
    achievements = relationship("PlayerAchievement", back_populates="student")
    student_contexts = relationship("StudentContext", back_populates="student")