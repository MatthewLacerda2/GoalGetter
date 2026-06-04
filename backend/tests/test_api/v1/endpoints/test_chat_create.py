import pytest
from datetime import datetime
from backend.schemas.chat_message import CreateMessageRequest, CreateMessageRequestItem, CreateMessageResponse

@pytest.mark.asyncio
async def test_create_message(auth_client, mock_gemini_messages_generator):
    """Test that the chat messages endpoint returns a valid response for a valid request."""
    payload = CreateMessageRequest(messages_list=[CreateMessageRequestItem(message="Explain flush, await, fresh in sqlalchemy", datetime=datetime.now())])
    response = await auth_client.post(
        "/api/v1/chat",
        json=payload.model_dump(mode='json')
    )
    chat_response = CreateMessageResponse.model_validate(response.json())
    assert response.status_code == 201
    assert isinstance(chat_response, CreateMessageResponse)

@pytest.mark.asyncio
async def test_create_message_unauthorized(client):
    """Test that the chat messages endpoint returns 403 without token."""
    payload = CreateMessageRequest(messages_list=[CreateMessageRequestItem(message="Test message", datetime=datetime.now())])
    response = await client.post(
        "/api/v1/chat",
        json=payload.model_dump(mode='json')
    )
    assert response.status_code == 403
