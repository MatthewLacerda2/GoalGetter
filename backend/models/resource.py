import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector

from backend.models.base import Base
from backend.utils.envs import NUM_DIMENSIONS

class StudyResourceType(Enum):
    pdf = "pdf"
    youtube = "youtube"
    webpage = "webpage"

class Resource(Base):
    __tablename__ = "resources"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    goal_id = Column(String(36), ForeignKey("goals.id"), nullable=False)
    objective_id = Column(String(36), ForeignKey("objectives.id"), nullable=True)
    resource_type = Column(StudyResourceType, nullable=False)
    name = Column(String, nullable=False)
    description = Column(String, nullable=False)
    language = Column(String, nullable=False)
    link = Column(String, nullable=False, unique=True)
    image_url = Column(String, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    description_embedding = Column(Vector(NUM_DIMENSIONS), nullable=False)
    
    goal = relationship("Goal", back_populates="resources")