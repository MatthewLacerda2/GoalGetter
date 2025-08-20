from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import List

class ChatMessageItem(BaseModel):
    id: str
    sender_id: str
    message: str
    created_at: datetime
    is_modern: bool
    is_liked: bool
    
    model_config = ConfigDict(from_attributes=True)

class ChatMessageResponse(BaseModel):
    messages: List[ChatMessageItem]
    
    model_config = ConfigDict(from_attributes=True)
    
class LikeMessageRequest(BaseModel):
    message_id: str
    like: bool
    
class CreateMessageRequest(BaseModel):
    message: str
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)
    
class ChatMessageItem(BaseModel):
    id: str
    sender_id: str
    array_id: str
    message: str
    created_at: datetime
    is_modern: bool
    
    model_config = ConfigDict(from_attributes=True)
    
class CreateMessageResponse(BaseModel):
    message: List[ChatMessageItem]
    
    model_config = ConfigDict(from_attributes=True)