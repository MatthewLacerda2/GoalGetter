import uuid
from datetime import datetime
from sqlalchemy import Column, DateTime, String
from sqlalchemy.dialects.postgresql import UUID
from backend.models.base import Base
from backend.utils.envs import NUM_DIMENSIONS
from pgvector.sqlalchemy import Vector

class Onboarding(Base):
    __tablename__ = "onboardings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    prompt = Column(String, nullable=False)
    questions_answer = Column(String, nullable=False)
    questions_answers_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
