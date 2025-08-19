from fastapi import APIRouter, Depends, Query
from typing import Optional
from backend.schemas.chat_message import ChatMessageResponse
from backend.models.chat_message import ChatMessage
from backend.models.student import Student
from backend.core.security import get_current_user
from sqlalchemy.ext.asyncio import AsyncSession
from backend.core.database import get_db
from sqlalchemy import select, desc

router = APIRouter()

@router.get("", response_model=ChatMessageResponse)
async def get_chat_messages(
    message_id: Optional[str] = Query(None, description="Optional message ID to start from"),
    limit: Optional[int] = Query(None, description="Optional limit on number of messages to return"),
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get chat messages for the authenticated user.
    
    - If message_id is provided, returns messages from that point
    - If limit is provided, returns up to that many messages
    - If neither is provided, returns default number of latest messages
    """
    if limit is None:
        limit = 20
    
    query = select(ChatMessage).where(ChatMessage.student_id == current_user.id)
    
    if message_id:
        query = query.where(ChatMessage.id >= message_id)
    
    query = query.order_by(desc(ChatMessage.created_at)).limit(limit)
    
    result = await db.execute(query)
    messages = result.scalars().all()
    
    return ChatMessageResponse(messages=messages)