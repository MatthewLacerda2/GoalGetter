from sqlalchemy import Column, String, ForeignKey, DateTime, Index
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector
from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base

class LearnInfo(Base):
    __tablename__ = "learn_infos"
    __table_args__ = (
        Index('idx_learn_info_objective_id', 'objective_id'),
    )
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    objective_id = Column(UUID(as_uuid=True), ForeignKey("objectives.id", ondelete="CASCADE"), nullable=False)
    title = Column(String, nullable=False)
    theme = Column(String, nullable=False)
    content = Column(String, nullable=False)
    theme_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    content_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    
    objective = relationship("Objective", back_populates="learn_infos")