from sqlalchemy import Column, String, DateTime, Float, ARRAY
from datetime import datetime
from backend.models.base import Base
from sqlalchemy.orm import relationship
import uuid
from backend.utils.envs import NUM_DIMENSIONS
from pgvector.sqlalchemy import Vector

class CourseGuideline(Base):
    __tablename__ = "course_guidelines"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    course_name = Column(String, nullable=False)
    course_description = Column(String, nullable=False)
    guideline = Column(ARRAY(String), nullable=False)
    guideline_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.now())   