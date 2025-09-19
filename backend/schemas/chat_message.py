from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import List

class ChatMessageItem(BaseModel):
    id: str
    sender_id: str
    message: str
    created_at: datetime
    is_liked: bool
    
    model_config = ConfigDict(from_attributes=True)

class ChatMessageItensList(BaseModel):
    messages: List[ChatMessageItem]

class ChatMessageResponse(BaseModel):
    messages: List[ChatMessageItem]
    
    model_config = ConfigDict(from_attributes=True)
    
class LikeMessageRequest(BaseModel):
    message_id: str
    like: bool
    
    model_config = ConfigDict(from_attributes=True)
    
class EditMessageRequest(BaseModel):
    message_id: str
    message: str
    
    model_config = ConfigDict(from_attributes=True)
    
class CreateMessageRequest(BaseModel):
    message: str
    
    model_config = ConfigDict(from_attributes=True)
    
class ChatMessageItem(BaseModel):
    id: str
    sender_id: str
    message: str
    created_at: datetime
    is_liked: bool
    
    model_config = ConfigDict(from_attributes=True)
    
class CreateMessageResponse(BaseModel):
    messages: List[ChatMessageItem]
    
    model_config = ConfigDict(from_attributes=True)