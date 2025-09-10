from sqlalchemy import Column, String, DateTime, ARRAY, Integer
from datetime import datetime
from backend.models.base import Base
import uuid
from backend.utils.envs import NUM_DIMENSIONS
from pgvector.sqlalchemy import Vector

class CourseGuideline(Base):
    __tablename__ = "course_guidelines"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    course_name = Column(String, nullable=False)
    guideline = Column(ARRAY(String), nullable=False)
    guideline_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    min_student_score = Column(Integer, nullable=False) #The student level where this guideline is appliable
    max_student_score = Column(Integer, nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.now())   