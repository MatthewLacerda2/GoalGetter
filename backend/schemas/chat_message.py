from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import List

class ChatMessageItem(BaseModel):
    id: str
    message: str
    created_at: datetime
    is_modern: bool
    
    model_config = ConfigDict(from_attributes=True)

class ChatMessageResponse(BaseModel):
    messages: List[ChatMessageItem]
    
    model_config = ConfigDict(from_attributes=True)