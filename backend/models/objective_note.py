import uuid
from datetime import datetime
from sqlalchemy.orm import relationship
from sqlalchemy import Boolean, Column, String, DateTime, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID
from pgvector.sqlalchemy import Vector
from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base

class ObjectiveNote(Base):
    __tablename__ = "objective_notes"
    __table_args__ = (
        Index('idx_objective_note_objective_id', 'objective_id'),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    objective_id = Column(UUID(as_uuid=True), ForeignKey("objectives.id", ondelete="CASCADE"), nullable=False)
    title = Column(String, nullable=False)
    info = Column(String, nullable=False)
    info_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    is_favorited = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    ai_model = Column(String, nullable=False)

    objective = relationship("Objective", back_populates="notes")