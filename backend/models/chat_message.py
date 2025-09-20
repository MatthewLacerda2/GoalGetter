import uuid
from datetime import datetime
from pgvector.sqlalchemy import Vector
from sqlalchemy.orm import relationship
from sqlalchemy import Column, String, DateTime, Boolean, Integer, ForeignKey
from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base
from backend.services.gemini.schema import ChatMessageWithGemini

class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    student_id = Column(String(36), ForeignKey("students.id"), nullable=False)
    sender_id = Column(String(36), nullable=False)
    array_id = Column(String(36), nullable=True, unique=False)
    message = Column(String, nullable=False)
    num_tokens = Column(Integer, nullable=True)
    is_liked = Column(Boolean, nullable=False, default=False)   #TODO: if an user likes the message, embed it!
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    message_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    
    student = relationship("Student", back_populates="chat_messages")
    
    def to_gemini_message(self) -> ChatMessageWithGemini:
        """Convert ChatMessage to ChatMessageWithGemini format"""
        role = "user" if self.student_id == self.sender_id else "assistant"
        time_str = self.created_at.strftime("%H:%M:%S")
        
        return ChatMessageWithGemini(
            message=self.message,
            role=role,
            time=time_str
        )