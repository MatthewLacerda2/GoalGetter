import uuid
from sqlalchemy.orm import relationship
from sqlalchemy import Column, String, DateTime, ForeignKey, Integer, Index
from sqlalchemy.dialects.postgresql import UUID
from backend.models.base import Base

class StreakDay(Base):
    __tablename__ = "streak_days"
    __table_args__ = (
        Index('idx_streak_day_student_date', 'student_id', 'date_time'),
    )

    id = Column(UUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4()))
    student_id = Column(UUID(as_uuid=False), ForeignKey("students.id"), nullable=False)
    date_time = Column(DateTime(timezone=True), nullable=False)
    xp = Column(Integer, nullable=False)

    student = relationship("Student", back_populates="streak_days")