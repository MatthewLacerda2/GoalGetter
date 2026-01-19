from pydantic import BaseModel, ConfigDict, field_validator
from datetime import datetime
from typing import List
from backend.utils.uuid_validators import convert_uuid_to_str

class ChatMessageItem(BaseModel):
    id: str
    sender_id: str
    message: str
    created_at: datetime
    is_liked: bool
    
    model_config = ConfigDict(from_attributes=True)
    
    @field_validator('id', mode='before')
    @classmethod
    def validate_id(cls, v):
        return convert_uuid_to_str(v)

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

class CreateMessageRequestItem(BaseModel):
    message: str
    datetime: datetime
    
    model_config = ConfigDict(from_attributes=True)

class CreateMessageRequest(BaseModel):
    messages_list: List[CreateMessageRequestItem]
    
class ChatMessageResponseItem(BaseModel):
    id: str
    sender_id: str
    message: str
    created_at: datetime
    is_liked: bool
    
    model_config = ConfigDict(from_attributes=True)
    
    @field_validator('id', mode='before')
    @classmethod
    def validate_id(cls, v):
        return convert_uuid_to_str(v)
    
class CreateMessageResponse(BaseModel):
    messages: List[ChatMessageResponseItem]
    
    model_config = ConfigDict(from_attributes=True)
