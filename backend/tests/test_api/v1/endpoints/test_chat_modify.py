import pytest
import uuid
from sqlalchemy import select
from backend.models.chat_message import ChatMessage
from backend.schemas.chat_message import ChatMessageItem, LikeMessageRequest, EditMessageRequest

@pytest.mark.asyncio
async def test_like_message(auth_client, chat_messages):
    """Test liking a chat message successfully."""
    payload = LikeMessageRequest(message_id=str(chat_messages[0].id), like=True)
    response = await auth_client.patch("/api/v1/chat/likes", json=payload.model_dump())
    assert response.status_code == 200
    chat_response = ChatMessageItem.model_validate(response.json())
    assert chat_response.is_liked is True

@pytest.mark.asyncio
async def test_like_message_not_found(auth_client):
    """Test liking a non-existent message returns 404."""
    payload = LikeMessageRequest(message_id="00000000-0000-0000-0000-000000000000", like=True)
    response = await auth_client.patch("/api/v1/chat/likes", json=payload.model_dump())
    assert response.status_code == 404

@pytest.mark.asyncio
async def test_edit_message(auth_client, chat_messages):
    """Test editing a message successfully."""
    payload = EditMessageRequest(message_id=str(chat_messages[0].id), message="Edited message")
    response = await auth_client.patch("/api/v1/chat/edit", json=payload.model_dump())
    assert response.status_code == 200
    chat_response = ChatMessageItem.model_validate(response.json())
    assert chat_response.message == "Edited message"

@pytest.mark.asyncio
async def test_edit_message_not_found(auth_client):
    """Test editing a non-existent message returns 404."""
    payload = EditMessageRequest(message_id="00000000-0000-0000-0000-000000000000", message="Edited message")
    response = await auth_client.patch("/api/v1/chat/edit", json=payload.model_dump())
    assert response.status_code == 404

@pytest.mark.asyncio
async def test_delete_message(auth_client, test_db, chat_messages):
    """Test deleting a message successfully."""
    id_to_delete = str(chat_messages[0].id)
    response = await auth_client.delete(f"/api/v1/chat/{id_to_delete}")
    assert response.status_code == 204
    
    query = select(ChatMessage).where(ChatMessage.id == uuid.UUID(id_to_delete))
    stored = (await test_db.execute(query)).scalar_one_or_none()
    assert stored is None

@pytest.mark.asyncio
async def test_delete_message_not_found(auth_client):
    """Test deleting a non-existent message returns 404."""
    response = await auth_client.delete("/api/v1/chat/00000000-0000-0000-0000-000000000000")
    assert response.status_code == 404

@pytest.mark.asyncio
async def test_modify_endpoints_unauthorized(client):
    """Test that edit, like, and delete messages endpoints return 403 without token."""
    r1 = await client.patch("/api/v1/chat/likes", json={"message_id": "msg1", "like": True})
    r2 = await client.patch("/api/v1/chat/edit", json={"message_id": "msg1", "message": "edit"})
    r3 = await client.delete("/api/v1/chat/msg1")
    assert r1.status_code == 403
    assert r2.status_code == 403
    assert r3.status_code == 403
