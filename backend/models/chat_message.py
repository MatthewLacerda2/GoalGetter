import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Boolean, Integer
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector

from backend.models.base import Base

#Messages are generated in an array of messages and sent separately
#Hence the array_id
#This makes the messages seem more natural
class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    array_id = Column(String(36), nullable=False, unique=False)
    message = Column(String, nullable=False)
    num_tokens = Column(Integer, nullable=False)
    embedding = Column(Vector(3072), nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    student_id = Column(String(36), nullable=False)
    sender_id = Column(String(36), nullable=False)
    is_liked = Column(Boolean, nullable=False, default=False)
    
    student = relationship("Student", back_populates="chat_messages")