import uuid
from sqlalchemy import Column, String, DateTime
from datetime import datetime
from backend.models.base import Base
from sqlalchemy.orm import relationship

class StudentContext(Base):
    __tablename__ = "student_contexts"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    student_id = Column(String(36), nullable=False)
    goal_id = Column(String(36), nullable=False)
    context = Column(String, nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    
    student = relationship("Student", back_populates="student_contexts")
    goal = relationship("Goal", back_populates="student_contexts")