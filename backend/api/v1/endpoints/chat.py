from fastapi import APIRouter, Depends, Query, HTTPException, Response
from typing import Optional
from backend.schemas.chat_message import ChatMessageResponse, ChatMessageItem, LikeMessageRequest
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

@router.patch("", response_model=ChatMessageItem)
async def like_message(
    payload: LikeMessageRequest,
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Like or remove like of a message for the authenticated user."""
    
    query = select(ChatMessage).where(ChatMessage.id == payload.message_id, ChatMessage.student_id == current_user.id)
    result = await db.execute(query)
    message = result.scalars().first()
    
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
    
    message.is_liked = payload.like
    await db.commit()
    
    return ChatMessageItem.model_validate(message)

@router.delete("/{message_id}", status_code=204)
async def delete_message(
    message_id: str,
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Delete a message for the authenticated user."""
    
    query = select(ChatMessage).where(ChatMessage.id == message_id, ChatMessage.student_id == current_user.id)
    result = await db.execute(query)
    message = result.scalars().first()
    
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
    
    await db.delete(message)
    await db.commit()
    
    return Response(status_code=204)