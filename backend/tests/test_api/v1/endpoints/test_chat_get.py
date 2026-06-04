import pytest
from backend.schemas.chat_message import ChatMessageResponse

@pytest.mark.asyncio
async def test_get_chat_messages_with_parameters(auth_client, chat_messages):
    """Test that get chat messages endpoint returns a valid response with filters."""
    limit = 10
    response = await auth_client.get(
        "/api/v1/chat",
        params={"message_id": str(chat_messages[1].id), "limit": limit}
    )
    chat_response = ChatMessageResponse.model_validate(response.json())
    assert response.status_code == 200
    assert len(chat_response.messages) <= limit

@pytest.mark.asyncio
async def test_get_chat_messages_no_parameters(auth_client, chat_messages):
    """Test that the chat messages endpoint works with no optional parameters."""
    response = await auth_client.get("/api/v1/chat")
    chat_response = ChatMessageResponse.model_validate(response.json())
    assert response.status_code == 200
    assert len(chat_response.messages) > 0

@pytest.mark.asyncio
async def test_get_chat_messages_unauthorized(client):
    """Test that the chat messages endpoint returns 403 without token."""
    response = await client.get("/api/v1/chat")
    assert response.status_code == 403
