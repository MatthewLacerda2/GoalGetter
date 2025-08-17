import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Enum
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector

from backend.models.base import Base
from backend.utils.envs import NUM_DIMENSIONS

class StudyResourceType(Enum):
    ebook = "ebook"
    youtuber = "youtuber"
    website = "website"

class Resource(Base):
    __tablename__ = "resources"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    resource_type = Column(StudyResourceType, nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    name = Column(String, nullable=False)
    description = Column(String, nullable=False)
    description_embedding = Column(Vector(NUM_DIMENSIONS), nullable=False)
    link = Column(String, nullable=False, unique=True)
    image_url = Column(String, nullable=True)
    goal_id = Column(String(36), nullable=False)
    student_id = Column(String(36), nullable=False)
    
    goal = relationship("Goal", back_populates="resources")
    student = relationship("Student", back_populates="resources")