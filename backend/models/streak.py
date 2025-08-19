import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey
from backend.models.base import Base
from sqlalchemy.orm import relationship

class Streak(Base):
    __tablename__ = "streaks"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    student_id = Column(String(36), ForeignKey("students.id"), nullable=False)
    start_date = Column(DateTime, nullable=False)
    last_streak_date = Column(DateTime, nullable=False)

    student = relationship("Student", back_populates="streaks")