import uuid
from sqlalchemy import Column, String, Boolean, DateTime
from backend.models.base import Base
from sqlalchemy.orm import relationship

class Streak(Base):
    __tablename__ = "streaks"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    student_id = Column(String(36), nullable=False)
    start_date = Column(DateTime, nullable=False)
    was_active_sunday = Column(Boolean, nullable=False, default=False)
    was_active_monday = Column(Boolean, nullable=False, default=False)
    was_active_tuesday = Column(Boolean, nullable=False, default=False)
    was_active_wednesday = Column(Boolean, nullable=False, default=False)
    was_active_thursday = Column(Boolean, nullable=False, default=False)
    was_active_friday = Column(Boolean, nullable=False, default=False)
    was_active_saturday = Column(Boolean, nullable=False, default=False)
    
    student = relationship("Student", back_populates="streaks")