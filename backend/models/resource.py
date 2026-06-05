import uuid
from enum import Enum
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum as SQLEnum, Index
from sqlalchemy.dialects.postgresql import UUID
from pgvector.sqlalchemy import Vector
from sqlalchemy.orm import relationship
from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base

class StudyResourceType(Enum):
    pdf = "pdf"
    webpage = "webpage"
    youtube = "youtube"

class Resource(Base):
    __tablename__ = "resources"
    __table_args__ = (
        Index('idx_resource_goal_id', 'goal_id'),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    goal_id = Column(UUID(as_uuid=True), ForeignKey("goals.id", ondelete="CASCADE"), nullable=False)
    resource_type = Column(SQLEnum(StudyResourceType), nullable=False)
    name = Column(String, nullable=False)
    description = Column(String, nullable=False)
    language = Column(String, nullable=False)
    link = Column(String, nullable=False, unique=True)
    image_url = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    description_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    
    goal = relationship("Goal", back_populates="resources")