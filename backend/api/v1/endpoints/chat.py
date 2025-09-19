import re
import uuid
from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from typing import Optional
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, Query, HTTPException, Response
from backend.core.database import get_db
from backend.models.student import Student
from backend.models.objective import Objective
from backend.core.security import get_current_user
from backend.models.chat_message import ChatMessage
from backend.models.student_context import StudentContext
from backend.utils.gemini.gemini_configs import get_gemini_embeddings
from backend.services.gemini.messages_generator import gemini_messages_generator
from backend.services.gemini.schema import ChatMessageWithGemini, StudentContextToChat
from backend.schemas.chat_message import ChatMessageResponse, ChatMessageItem, LikeMessageRequest, CreateMessageRequest, CreateMessageResponse, EditMessageRequest

router = APIRouter()

@router.post("", response_model=CreateMessageResponse, status_code=201)
async def create_message(
    request: CreateMessageRequest,
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new chat message for the authenticated user."""
    
    request_array_id = str(uuid.uuid4())
    full_text = ". ".join([m.message for m in request.message])
    full_text_embedding = get_gemini_embeddings(full_text)
    
    items: List[ChatMessageItem] = [ChatMessageItem(
        id=str(uuid.uuid4()),
        array_id=request_array_id,
        sender_id=current_user.id,
        message=m.message,
        is_liked=False,
        created_at=datetime.now(),
        message_embedding=full_text_embedding
    ) for m in request.message]
    
    stmt = select(ChatMessage).where(
        ChatMessage.student_id == current_user.id,
        ChatMessage.created_at > datetime.now() - timedelta(days=1)
    )
    result = await db.execute(stmt)
    yesterday_messages = result.scalars().all()
    
    yesterday2gemini = [ChatMessageWithGemini(
        message=y.message,
        role="user" if y.sender_id == y.student_id else "assistant",
        time=y.created_at.strftime("%H:%M:%S")
    ) for y in yesterday_messages]
    
    items2gemini = [ChatMessageWithGemini(
        message=m.message,
        role="user",
        time=m.created_at.strftime("%H:%M:%S")
    ) for m in items]
    
    stmt = select(Objective).where(Objective.goal_id == current_user.goal_id).order_by(Objective.created_at.desc()).limit(1)
    result = await db.execute(stmt)
    objective = result.scalar_one_or_none()
    
    stmt = select(StudentContext).where(
        StudentContext.objective_id == objective.id,
        StudentContext.is_still_valid == True,
        StudentContext.state_embedding.cosine_similarity(full_text_embedding) > 0.8
    ).order_by(
        StudentContext.created_at.desc(),
        StudentContext.state_embedding.cosine_similarity(full_text_embedding).desc()
    ).limit(8)
    result = await db.execute(stmt)
    student_contexts = result.scalars().all()
    
    context = [StudentContextToChat(
        state=sc.state,
        metacognition=sc.metacognition
    ) for sc in student_contexts]
    
    ai_response = gemini_messages_generator(
        items2gemini, context, objective.name, objective.description, current_user.goal_name
    )
    
    array_id = str(uuid.uuid4())
    ai_chat_messages: List[ChatMessage] = [ChatMessage(
        id=str(uuid.uuid4()),
        student_id=current_user.id,
        sender_id="gemini-2.5-flash",
        array_id=array_id,
        message=message,
        num_tokens=len([w for w in re.split(r"[ \n.,?]", message) if w]),#TODO: improve this
        is_liked=False
    ) for message in ai_response.messages]
        
    db.add_all(items)
    db.add_all(ai_chat_messages)
    await db.commit()
    
    stmt = select(ChatMessage).where(ChatMessage.array_id == array_id).order_by(ChatMessage.created_at)
    result = await db.execute(stmt)
    db_ai_chat_messages = result.scalars().all()
        
    response = CreateMessageResponse(
        messages=[ChatMessageItem(
            id=message.id,
            sender_id=message.sender_id,
            message=message.message,
            created_at=message.created_at,
            is_liked=message.is_liked
        ) for message in db_ai_chat_messages]
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

#We only embed AI-generated messages.
#We put whole array together (for context) and embed it
@router.patch("/likes", response_model=ChatMessageItem)
async def like_message(
    request: LikeMessageRequest,
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Like or remove like of a message for the authenticated user."""
    
    stmt = select(ChatMessage).where(ChatMessage.id == request.message_id, ChatMessage.student_id == current_user.id)
    result = await db.execute(stmt)
    message = result.scalars().first()
    
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
    
    message.is_liked = request.like
    
    if message.sender_id != message.student_id:
        
        stmt = select(ChatMessage).where(ChatMessage.array_id == message.array_id)
        result = await db.execute(stmt)
        array = result.scalars().all()
        
        full_text = "\n".join([msg.message for msg in array])
        full_text_embedding = get_gemini_embeddings(full_text)
        
        message.message_embedding = full_text_embedding
    
    await db.commit()
    
    return ChatMessageItem.model_validate(message)

@router.patch("/edit", response_model=ChatMessageItem)
async def edit_message(
    request: EditMessageRequest,
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Edit a message for the authenticated user."""
    
    query = select(ChatMessage).where(ChatMessage.id == request.message_id, ChatMessage.student_id == current_user.id)
    result = await db.execute(query)
    message = result.scalars().first()
    
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
    
    message.message = request.message
    
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