from sqlalchemy import Column, String, DateTime, Float, ARRAY
from datetime import datetime
from backend.models.base import Base
from sqlalchemy.orm import relationship
import uuid
from backend.utils.envs import NUM_DIMENSIONS
from pgvector.sqlalchemy import Vector

class CuratedCourse(Base):
    __tablename__ = "curated_courses"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    description = Column(String, nullable=False)
    guidelines = Column(ARRAY(String), nullable=False)
    theoretical_score = Column(Float, nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    description_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)