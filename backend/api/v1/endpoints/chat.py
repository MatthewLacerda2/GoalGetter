import re
import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from typing import Optional
from fastapi import APIRouter, Depends, Query, HTTPException, Response
from backend.core.database import get_db
from backend.core.security import get_current_user
from backend.models.student import Student
from backend.models.chat_message import ChatMessage
from backend.schemas.chat_message import LikeMessageRequest, EditMessageRequest
from backend.services.gemini.chat.chat import gemini_messages_generator
from backend.services.gemini.chat.schema import GeminiChatMessage, StudentContextToChat
from backend.schemas.chat_message import ChatMessageResponse, ChatMessageItem, CreateMessageRequest, CreateMessageResponse, ChatMessageResponseItem
from backend.repositories.objective_repository import ObjectiveRepository
from backend.repositories.chat_message_repository import ChatMessageRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.utils.gemini.gemini_configs import get_gemini_embeddings

router = APIRouter()

@router.post("", response_model=CreateMessageResponse, status_code=201)
async def create_message(
    request: CreateMessageRequest,
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new chat message for the authenticated user."""
    
    chat_repo = ChatMessageRepository(db)
    
    request_array_id = str(uuid.uuid4())
    full_text = ". ".join([m.message for m in request.messages_list])
    full_text_embedding = get_gemini_embeddings(full_text)
    
    request_chat_messages: List[ChatMessage] = [
        ChatMessage(
            id=str(uuid.uuid4()),
            student_id=current_user.id,
            sender_id=current_user.id,
            array_id=request_array_id,
            created_at=m.datetime,
            message=m.message,
            message_embedding=full_text_embedding,
            is_liked=False,
        ) for m in request.messages_list
    ]
    
    yesterday_chat_messages = await chat_repo.get_recent_messages(current_user.id, days=1)
    
    yesterday_4_gemini: List[GeminiChatMessage] = [
        GeminiChatMessage(
            message=y.message,
            time=y.created_at.strftime("%H:%M:%S"),
            role="user" if y.sender_id == y.student_id else "assistant",
        ) for y in yesterday_chat_messages
    ]
    
    request_to_gemini: List[GeminiChatMessage] = [
        GeminiChatMessage(
            message=m.message,
            role="user",
            time=m.created_at.strftime("%H:%M:%S")
        ) for m in request_chat_messages
    ]
    
    total_chat_to_gemini = yesterday_4_gemini + request_to_gemini
    
    objective_repo = ObjectiveRepository(db)
    objective = await objective_repo.get_latest_by_goal_id(current_user.goal_id)
    
    student_context_repo = StudentContextRepository(db)
    student_contexts = await student_context_repo.get_by_student_and_objective(current_user.id, objective.id, 8)
    
    context = [
        StudentContextToChat(
            state=sc.state,
            metacognition=sc.metacognition
        ) for sc in student_contexts
    ]
    
    ai_response = gemini_messages_generator(
        total_chat_to_gemini, context, objective.name, objective.description, current_user.goal_name
    )
    
    full_ai_text = ". ".join([m for m in ai_response.messages])
    full_ai_text_embedding = get_gemini_embeddings(full_ai_text)
    
    array_id = str(uuid.uuid4())
    ai_chat_messages: List[ChatMessage] = [
        ChatMessage(
            id=str(uuid.uuid4()),
            student_id=current_user.id,
            sender_id="gemini-2.5-flash",
            array_id=array_id,
            message=message,
            is_liked=False,
            message_embedding=full_ai_text_embedding
        ) for message in ai_response.messages
    ]

    await chat_repo.create_many(request_chat_messages)
    await chat_repo.create_many(ai_chat_messages)
    
    await db.commit()
    
    for message in ai_chat_messages:
        await db.refresh(message)
    
    await db.commit()
    
    response = CreateMessageResponse(
        messages=[
            ChatMessageResponseItem(
                id=message.id,
                sender_id=message.sender_id,
                message=message.message,
                created_at=message.created_at,
                is_liked=message.is_liked
            ) for message in ai_chat_messages
        ]
    )
    
    return response

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
    await chat_repo.update(message)
    await db.commit()
    
    return ChatMessageItem.model_validate(message)

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
    updated_message = await chat_repo.update(message)
    await db.commit()
    
    return ChatMessageItem.model_validate(updated_message)

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