import uuid
from datetime import datetime
from pgvector.sqlalchemy import Vector
from sqlalchemy.orm import relationship
from sqlalchemy import Column, String, DateTime, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID
from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base

class ChatMessage(Base):
    __tablename__ = "chat_messages"
    __table_args__ = (
        Index('idx_chat_message_student_created', 'student_id', 'created_at'),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    prompt = Column(String, nullable=False)
    prompt_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    tutor_response = Column(String, nullable=False)
    tutor_response_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    
    student = relationship("Student", back_populates="chat_messages")