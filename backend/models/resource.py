import uuid
from enum import Enum
from datetime import datetime
from sqlalchemy.orm import relationship
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum as SQLEnum, Index
from sqlalchemy.dialects.postgresql import UUID
from pgvector.sqlalchemy import Vector
from backend.models.base import Base
from backend.utils.envs import NUM_DIMENSIONS

class StudyResourceType(Enum):
    pdf = "pdf"
    webpage = "webpage"
    youtube = "youtube"

class Resource(Base):
    __tablename__ = "resources"
    __table_args__ = (
        Index('idx_resource_goal_id', 'goal_id'),
        Index('idx_resource_objective_id', 'objective_id'),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    goal_id = Column(UUID(as_uuid=True), ForeignKey("goals.id"), nullable=False)
    objective_id = Column(UUID(as_uuid=True), ForeignKey("objectives.id"), nullable=True)
    resource_type = Column(SQLEnum(StudyResourceType), nullable=False)
    name = Column(String, nullable=False)
    description = Column(String, nullable=False)
    language = Column(String, nullable=False)
    link = Column(String, nullable=False, unique=True)
    image_url = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    description_embedding = Column(Vector(NUM_DIMENSIONS), nullable=False)
    
    goal = relationship("Goal", back_populates="resources")