from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from fastapi import APIRouter, Depends, Query, HTTPException, Response
from backend.core.database import get_db
from backend.core.security import get_current_user
from backend.models.student import Student
from backend.schemas.chat_message import LikeMessageRequest, EditMessageRequest
from backend.schemas.chat_message import ChatMessageResponse, ChatMessageItem, CreateMessageRequest, CreateMessageResponse, ChatMessageResponseItem
from backend.repositories.chat_message_repository import ChatMessageRepository
from backend.services.chat.chat_service import create_chat_message_service

router = APIRouter()

@router.post("", response_model=CreateMessageResponse, status_code=201)
async def create_message(
    request: CreateMessageRequest,
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new chat message for the authenticated user."""
    ai_chat_messages = await create_chat_message_service(request, current_user, db)
    
    # Extract attribute values immediately to avoid MissingGreenlet errors
    # Access ORM attributes while still in async context
    message_data = [
        {
            "id": str(msg.id),
            "sender_id": msg.sender_id,
            "message": msg.message,
            "created_at": msg.created_at,
            "is_liked": msg.is_liked
        }
        for msg in ai_chat_messages
    ]
    
    return CreateMessageResponse(
        messages=[
            ChatMessageResponseItem(**data) for data in message_data
        ]
    )

@router.get("", response_model=ChatMessageResponse)
async def get_chat_messages(
    message_id: Optional[str] = Query(None, description="Get messages before this message ID (for backward pagination)"),
    limit: Optional[int] = Query(None),
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    if limit is None:
        limit = 20
    
    chat_repo = ChatMessageRepository(db)
    # Use message_id as before_message_id for backward pagination
    messages = await chat_repo.get_by_student_id(current_user.id, limit, message_id)
    
    return ChatMessageResponse(messages=messages)

@router.patch("/likes", response_model=ChatMessageItem)
async def like_message(
    request: LikeMessageRequest,
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    chat_repo = ChatMessageRepository(db)
    message = await chat_repo.get_by_student_and_message_id(current_user.id, request.message_id)
    
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
    
    message.is_liked = request.like
    # Extract attribute values BEFORE commit to avoid MissingGreenlet errors
    # Access ORM attributes while still in async context
    message_data = {
        "id": str(message.id),
        "sender_id": message.sender_id,
        "message": message.message,
        "created_at": message.created_at,
        "is_liked": message.is_liked
    }
    await chat_repo.update(message)
    await db.commit()
    
    return ChatMessageItem(**message_data)

@router.patch("/edit", response_model=ChatMessageItem)
async def edit_message(
    request: EditMessageRequest,
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Edit a message for the authenticated user."""
    
    chat_repo = ChatMessageRepository(db)
    message = await chat_repo.get_by_student_and_message_id(current_user.id, request.message_id)
    
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
    
    message.message = request.message
    # Extract attribute values BEFORE commit to avoid MissingGreenlet errors
    # Access ORM attributes while still in async context
    message_data = {
        "id": str(message.id),
        "sender_id": message.sender_id,
        "message": message.message,
        "created_at": message.created_at,
        "is_liked": message.is_liked
    }
    await chat_repo.update(message)
    await db.commit()
    
    return ChatMessageItem(**message_data)

@router.delete("/{message_id}", status_code=204)
async def delete_message(
    message_id: str,
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Delete a message for the authenticated user."""
    
    chat_repo = ChatMessageRepository(db)
    message = await chat_repo.get_by_student_and_message_id(current_user.id, message_id)
    
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
    
    await chat_repo.delete(message_id)
    await db.commit()
    
    return Response(status_code=204)
