import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey
from backend.models.base import Base
from sqlalchemy.orm import relationship

class StreakDay(Base):
    __tablename__ = "streak_days"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    student_id = Column(String(36), ForeignKey("students.id"), nullable=False)
    date_time = Column(DateTime, nullable=False)

    student = relationship("Student", back_populates="streak_days")