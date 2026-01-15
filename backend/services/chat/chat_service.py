import uuid
from typing import List
from sqlalchemy.ext.asyncio import AsyncSession
from backend.models.student import Student
from backend.models.chat_message import ChatMessage
from backend.schemas.chat_message import CreateMessageRequest
from backend.services.ollama.chat.chat import ollama_messages_generator
from backend.services.ollama.chat.schema import OllamaChatMessage, StudentContextToChat
from backend.repositories.chat_message_repository import ChatMessageRepository
from backend.repositories.objective_repository import ObjectiveRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.utils.gemini.gemini_configs import get_gemini_embeddings

# Constants
RECENT_MESSAGES_DAYS = 1
STUDENT_CONTEXT_LIMIT = 8
AI_MODEL_NAME = "gpt-oss:120b-cloud"


def _create_user_messages_from_request(
    request: CreateMessageRequest,
    student_id,
    full_text_embedding
) -> List[ChatMessage]:
    """Transform request messages to ChatMessage models."""
    request_array_id = str(uuid.uuid4())
    return [
        ChatMessage(
            id=uuid.uuid4(),
            student_id=student_id,
            sender_id=str(student_id),
            array_id=request_array_id,
            created_at=m.datetime,
            message=m.message,
            message_embedding=full_text_embedding,
            is_liked=False,
        ) for m in request.messages_list
    ]


def _convert_to_ollama_format(messages: List[ChatMessage]) -> List[OllamaChatMessage]:
    """Convert ChatMessage to OllamaChatMessage format."""
    return [
        OllamaChatMessage(
            message=msg.message,
            time=msg.created_at.strftime("%H:%M:%S"),
            role="user" if msg.sender_id == str(msg.student_id) else "assistant",
        ) for msg in messages
    ]


def _create_ai_messages_from_response(
    ai_response_messages: List[str],
    student_id,
    full_ai_text_embedding
) -> List[ChatMessage]:
    """Transform AI response to ChatMessage models."""
    array_id = str(uuid.uuid4())
    return [
        ChatMessage(
            id=uuid.uuid4(),
            student_id=student_id,
            sender_id=AI_MODEL_NAME,
            array_id=array_id,
            message=message,
            is_liked=False,
            message_embedding=full_ai_text_embedding
        ) for message in ai_response_messages
    ]


async def create_chat_message_service(
    request: CreateMessageRequest,
    current_user: Student,
    db: AsyncSession
) -> List[ChatMessage]:
    """
    Main service function that orchestrates chat message creation.
    
    Returns:
        List of AI chat messages that were created
    """
    chat_repo = ChatMessageRepository(db)
    
    # Create user messages from request
    full_text = ". ".join([m.message for m in request.messages_list])
    full_text_embedding = get_gemini_embeddings(full_text)
    user_messages = _create_user_messages_from_request(
        request, current_user.id, full_text_embedding
    )
    
    # Get recent messages for context
    recent_chat_messages = await chat_repo.get_recent_messages(
        current_user.id, days=RECENT_MESSAGES_DAYS
    )
    
    # Convert to Ollama format
    recent_messages_ollama = _convert_to_ollama_format(recent_chat_messages)
    new_messages_ollama = _convert_to_ollama_format(user_messages)
    chat_history_ollama = recent_messages_ollama + new_messages_ollama
    
    # Get objective and student context
    objective_repo = ObjectiveRepository(db)
    objective = await objective_repo.get_latest_by_goal_id(current_user.goal_id)
    
    student_context_repo = StudentContextRepository(db)
    student_contexts = await student_context_repo.get_by_student_and_objective(
        current_user.id, objective.id, STUDENT_CONTEXT_LIMIT
    )
    
    context = [
        StudentContextToChat(
            state=sc.state,
            metacognition=sc.metacognition
        ) for sc in student_contexts
    ]
    
    # Generate AI response
    ai_response = ollama_messages_generator(
        chat_history_ollama,
        context,
        objective.name,
        objective.description,
        current_user.goal_name
    )
    
    # Create AI messages
    full_ai_text = ". ".join([m for m in ai_response.messages])
    full_ai_text_embedding = get_gemini_embeddings(full_ai_text)
    ai_chat_messages = _create_ai_messages_from_response(
        ai_response.messages,
        current_user.id,
        full_ai_text_embedding
    )
    
    # Save all messages
    await chat_repo.create_many(user_messages)
    await chat_repo.create_many(ai_chat_messages)
    await db.commit()
    
    return ai_chat_messages
