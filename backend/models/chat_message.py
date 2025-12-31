import uuid
from datetime import datetime
from pgvector.sqlalchemy import Vector
from sqlalchemy.orm import relationship
from sqlalchemy import Column, String, DateTime, Boolean, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID
from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base
from backend.services.gemini.chat.schema import GeminiChatMessage

class ChatMessage(Base):
    __tablename__ = "chat_messages"
    __table_args__ = (
        Index('idx_chat_message_student_created', 'student_id', 'created_at'),
    )

    id = Column(UUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4()))
    student_id = Column(UUID(as_uuid=False), ForeignKey("students.id"), nullable=False)
    sender_id = Column(String(36), nullable=False)  #Who sent this message? If student, this'll be == student_id. If AI, this'll be model's name
    array_id = Column(String(36), nullable=True, unique=False)
    message = Column(String, nullable=False)
    is_liked = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    message_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    
    student = relationship("Student", back_populates="chat_messages")
    
    def to_gemini_message(self) -> GeminiChatMessage:
        """Convert ChatMessage to ChatMessageWithGemini format"""
        role = "user" if self.student_id == self.sender_id else "assistant"
        time_str = self.created_at.strftime("%H:%M:%S")
        
        return GeminiChatMessage(
            message=self.message,
            role=role,
            time=time_str
        )