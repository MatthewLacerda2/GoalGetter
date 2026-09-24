"""The tutor chat, scoped to the student's active goal (404 `No active goal`
without one). The API speaks in exchanges: one row per prompt + reply."""

from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from backend.api.v1.goal_dependencies import get_active_goal
from backend.core import clock
from backend.core.database import get_db
from backend.models.chat_message import ChatMessage
from backend.models.goal import Goal
from backend.repositories.chat_message_repository import ChatMessageRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.schemas.tutor import ChatExchange, LikeRequest, TutorMessageRequest
from backend.services.gemini.chat.chat import gemini_messages_generator
from backend.services.gemini.chat.schema import GeminiChatMessage, StudentContextToChat
from backend.utils.gemini.gemini_guard import run_gemini

router = APIRouter()

# How many past exchanges (each = one user turn + one model turn) Gemini sees.
# The chat is WhatsApp-short, so the last few exchanges carry the thread; what
# the tutor should remember for longer lives in the student contexts, which are
# sent on every call. Ten keeps the fast model's prompt small and its cost flat.
HISTORY_WINDOW = 10
PAGE_SIZE = 20
MAX_PAGE_SIZE = 50
EXCHANGE_NOT_FOUND = "Message not found"


def _history_turns(exchanges: list[ChatMessage]) -> list[GeminiChatMessage]:
    """Oldest first, alternating user / model turns."""
    turns = []
    for ex in sorted(exchanges, key=lambda e: e.created_at):
        time = clock.app_local(ex.created_at).isoformat()
        turns.append(GeminiChatMessage(role="user", message=ex.prompt, time=time))
        turns.append(
            GeminiChatMessage(role="model", message="\n".join(ex.tutor_responses), time=time)
        )
    return turns


@router.get("/messages", response_model=list[ChatExchange])
async def list_messages(
    before: datetime | None = Query(None, description="Only exchanges older than this created_at"),
    limit: int = Query(PAGE_SIZE, ge=1, le=MAX_PAGE_SIZE),
    goal: Goal = Depends(get_active_goal),
    db: AsyncSession = Depends(get_db),
):
    """The active goal's exchanges, newest first. Pass the last one's
    `created_at` as `before` for the next (older) page."""
    return await ChatMessageRepository(db).list_by_goal(goal.id, limit, before)


@router.post("/messages", response_model=ChatExchange, status_code=status.HTTP_201_CREATED)
async def send_message(
    payload: TutorMessageRequest,
    goal: Goal = Depends(get_active_goal),
    db: AsyncSession = Depends(get_db),
):
    """Send the student's message with this goal's recent history and the
    student's still-valid contexts; store and return the exchange.

    The contexts are the student's, not the goal's (#87): what is specific to
    this goal already reaches the prompt as its name and description."""
    repo = ChatMessageRepository(db)
    history = _history_turns(await repo.list_by_goal(goal.id, HISTORY_WINDOW))
    history.append(
        GeminiChatMessage(
            role="user", message=payload.message, time=clock.app_local(clock.now()).isoformat()
        )
    )
    contexts = [
        StudentContextToChat(state=c.state, metacognition=c.metacognition)
        for c in await StudentContextRepository(db).list_valid(goal.student_id)
    ]
    reply = await run_gemini(
        gemini_messages_generator, history, contexts, goal.name, goal.description
    )

    exchange = await repo.create(
        ChatMessage(
            student_id=goal.student_id,
            goal_id=goal.id,
            prompt=payload.message,
            tutor_responses=reply.messages,
        )
    )
    await db.commit()
    return exchange


@router.put("/messages/{message_id}/like", response_model=ChatExchange)
async def like_message(
    message_id: UUID,
    payload: LikeRequest,
    goal: Goal = Depends(get_active_goal),
    db: AsyncSession = Depends(get_db),
):
    """Set the like on a reply. An exchange outside the active goal (someone
    else's, or another goal's) is 404, so its existence never leaks."""
    repo = ChatMessageRepository(db)
    exchange = await repo.get_by_id(message_id)
    if exchange is None or exchange.goal_id != goal.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=EXCHANGE_NOT_FOUND)
    exchange.is_liked = payload.is_liked
    await repo.update(exchange)
    await db.commit()
    return exchange
