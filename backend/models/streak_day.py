import uuid
from sqlalchemy.orm import relationship
from sqlalchemy import Column, String, DateTime, ForeignKey, Integer
from backend.models.base import Base

class StreakDay(Base):
    __tablename__ = "streak_days"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    student_id = Column(String(36), ForeignKey("students.id"), nullable=False)
    date_time = Column(DateTime, nullable=False)
    xp = Column(Integer, nullable=False)

    student = relationship("Student", back_populates="streak_days")