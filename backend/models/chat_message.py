import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Boolean, Integer, ForeignKey
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector

from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base

#Messages are generated in List[str] and displayed separately
#This makes them seem more natural
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