from fastapi import APIRouter, Depends, Query, HTTPException, Response
from sqlalchemy import select, desc
from datetime import datetime
from typing import Optional
from typing import List
import uuid
import re
from sqlalchemy.ext.asyncio import AsyncSession
from backend.core.database import get_db
from backend.core.security import get_current_user
from backend.models.student import Student
from backend.models.chat_message import ChatMessage
from backend.schemas.chat_message import ChatMessageResponse, ChatMessageItem, LikeMessageRequest, CreateMessageRequest, CreateMessageResponse, EditMessageRequest

router = APIRouter()

#TODO: make the AI get context from:
# - the student's chat history
# - the student_context
# - the student's resources
# - the student's objective, notes and goal

#We must also:

# - generate context as chat goes on
# - generate the lessons
    # - Those must have and generate context (metacognition)
    # - When done, it must:
        # - generate new context
        # - generate new objective
        # - update the student's streak and give XP
        # - give an award, if applicable


@router.post("", response_model=CreateMessageResponse, status_code=201)
async def create_message(
    payload: CreateMessageRequest,
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new chat message for the authenticated user."""
    
    message = ChatMessage(
        student_id=current_user.id,
        sender_id=current_user.id,
        message=payload.message,
        created_at=datetime.now()
    )
    
    db.add(message)
    await db.commit()
    
    mocked_responses: List[str] = ["First message", "Second message", "Third message"]
    array_id = str(uuid.uuid4())
    items: List[ChatMessageItem] = []
    
    for i in range(len(mocked_responses)):
        message = ChatMessageItem(
            id=str(uuid.uuid4()),
            sender_id=current_user.id,
            message=mocked_responses[i],
            created_at=datetime.now(),
            is_liked=False
        )
        items.append(message)
    
    mocked_messages: List[ChatMessage] = []
    for i in range(len(mocked_responses)):
        aux_message = ChatMessage(
            student_id=current_user.id,
            sender_id="gemini-2.5-flash",
            array_id=array_id,
            message=mocked_responses[i],
            num_tokens=len([w for w in re.split(r"[ \n.,?]", mocked_responses[i]) if w]),
            is_liked=False
        )
        
        mocked_messages.append(aux_message)
        
    db.add_all(mocked_messages)
    await db.commit()
        
    response = CreateMessageResponse(
        messages=items
    )
    
    return response

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

@router.patch("/likes", response_model=ChatMessageItem)
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

@router.patch("/edit", response_model=ChatMessageItem)
async def edit_message(
    payload: EditMessageRequest,
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Edit a message for the authenticated user."""
    
    query = select(ChatMessage).where(ChatMessage.id == payload.message_id, ChatMessage.student_id == current_user.id)
    result = await db.execute(query)
    message = result.scalars().first()
    
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
    
    message.message = payload.message
    
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