import pytest
import uuid
from datetime import datetime
from sqlalchemy import select
from backend.models.chat_message import ChatMessage
from backend.schemas.chat_message import CreateMessageRequestItem
from backend.schemas.chat_message import ChatMessageResponse, ChatMessageItem, LikeMessageRequest, CreateMessageResponse, CreateMessageRequest, EditMessageRequest

def create_chat_messages(user_id):
    """Create a predefined array of chat messages for testing"""

    TEST_NAMESPACE = uuid.UUID('00000000-0000-0000-0000-000000000001')

    messages = []
    for i in range(15):
        msg = ChatMessage(
            id=uuid.uuid5(TEST_NAMESPACE, f"Message {i}"),
            message=f"Message {i}",
            sender_id=str(user_id),
            array_id="array1",
            created_at=datetime.now(),
            student_id=user_id
        )
        messages.append(msg)
    return messages

@pytest.mark.asyncio
async def test_get_chat_messages_with_parameters(authenticated_client, test_db, test_user):
    """Test that get chat messages endpoint returns a valid response."""
    
    client, access_token = authenticated_client
    
    chat_messages = create_chat_messages(test_user.id)
    
    for msg in chat_messages:
        test_db.add(msg)
    await test_db.commit()
    
    limit = 10
    
    response = await client.get(
        "/api/v1/chat",
        headers={"Authorization": f"Bearer {access_token}"},
        params={"message_id": str(chat_messages[1].id), "limit": limit}
    )
    
    chat_response = ChatMessageResponse.model_validate(response.json())
    
    assert response.status_code == 200
    assert isinstance(chat_response, ChatMessageResponse)
    assert len(chat_response.messages) <= limit

@pytest.mark.asyncio
async def test_get_chat_messages_no_parameters(authenticated_client, test_db, test_user):
    """Test that the chat messages endpoint works with no optional parameters."""
    
    client, access_token = authenticated_client
    
    chat_messages = create_chat_messages(test_user.id)
    
    for msg in chat_messages:
        test_db.add(msg)
    await test_db.commit()
    
    response = await client.get(
        "/api/v1/chat",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    chat_response = ChatMessageResponse.model_validate(response.json())
    
    assert response.status_code == 200
    assert isinstance(chat_response, ChatMessageResponse)
    assert len(chat_response.messages) > 0

@pytest.mark.asyncio
async def test_get_chat_messages_unauthorized(client):
    """Test that the chat messages endpoint returns 403 without token."""
    response = await client.get(
        "/api/v1/chat",
        params={"message_id": "msg1", "limit": 10}
    )
    
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_get_chat_messages_invalid_token(client, mock_google_verify):
    """Test that the chat messages endpoint returns 401 with invalid token."""
    mock_google_verify.side_effect = Exception("Invalid token")
    
    response = await client.get(
        "/api/v1/chat",
        headers={"Authorization": "Bearer invalid_token"},
        params={"message_id": "msg1", "limit": 10}
    )
    
    assert response.status_code == 401

@pytest.mark.asyncio
async def test_like_message_unauthorized(client):
    """Test that the chat messages endpoint returns 403 without token."""
    response = await client.patch(
        "/api/v1/chat/likes",
        json={"message_id": "msg1", "like": True}
    )

    assert response.status_code == 403
    
@pytest.mark.asyncio
async def test_like_message_not_found(authenticated_client, test_db, test_user):
    """Test that the chat messages endpoint returns 404 if the message is not found."""
    
    client, access_token = authenticated_client
    
    payload = LikeMessageRequest(message_id="00000000-0000-0000-0000-000000000000", like=True)
    
    response = await client.patch(
        "/api/v1/chat/likes",
        json=payload.model_dump(),
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 404
    assert response.json()["detail"] == "Message not found"

@pytest.mark.asyncio
async def test_like_message(authenticated_client, test_db, test_user):
    """Test that the chat messages endpoint returns a valid response for a valid request."""
    
    client, access_token = authenticated_client
    
    chat_messages = create_chat_messages(test_user.id)
    
    for msg in chat_messages:
        test_db.add(msg)
    await test_db.commit()
    
    payload = LikeMessageRequest(message_id=str(chat_messages[0].id), like=True)
    
    response = await client.patch(
        "/api/v1/chat/likes",
        json=payload.model_dump(),
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    chat_response = ChatMessageItem.model_validate(response.json())
    
    assert response.status_code == 200
    assert isinstance(chat_response, ChatMessageItem)
    assert chat_response.is_liked == payload.like
    assert chat_response.id == str(chat_messages[0].id)
    assert chat_response.sender_id == chat_messages[0].sender_id
    assert chat_response.message == chat_messages[0].message
    assert chat_response.created_at == chat_messages[0].created_at

@pytest.mark.asyncio
async def test_edit_message(authenticated_client, test_db, test_user):
    """Test that the chat messages endpoint returns a valid response for a valid request."""
    
    client, access_token = authenticated_client
    
    chat_messages = create_chat_messages(test_user.id)
    
    for msg in chat_messages:
        test_db.add(msg)
    await test_db.commit()
    
    payload = EditMessageRequest(message_id=str(chat_messages[0].id), message="Edited message")
    
    response = await client.patch(
        "/api/v1/chat/edit",
        json=payload.model_dump(),
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    chat_response = ChatMessageItem.model_validate(response.json())
    
    assert response.status_code == 200
    assert isinstance(chat_response, ChatMessageItem)
    assert chat_response.is_liked == chat_messages[0].is_liked
    assert chat_response.id == str(chat_messages[0].id)
    assert chat_response.sender_id == chat_messages[0].sender_id
    assert chat_response.message == payload.message
    assert chat_response.created_at == chat_messages[0].created_at

@pytest.mark.asyncio
async def test_edit_message_unauthorized(client):
    """Test that the chat messages endpoint returns 403 without token."""
    response = await client.patch(
        "/api/v1/chat/edit",
        json={"message_id": "msg1", "message": "Edited message"}
    )

    assert response.status_code == 403

@pytest.mark.asyncio
async def test_edit_message_not_found(authenticated_client, test_user):
    """Test that the chat messages endpoint returns 404 if the message is not found."""
    
    client, access_token = authenticated_client
    
    payload = EditMessageRequest(message_id="00000000-0000-0000-0000-000000000000", message="Edited message")
    
    response = await client.patch(
        "/api/v1/chat/edit",
        json=payload.model_dump(),
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 404
    assert response.json()["detail"] == "Message not found"

@pytest.mark.asyncio
async def test_delete_message(authenticated_client, test_db, test_user):
    """Test that the chat messages endpoint returns a valid response for a valid request."""
    
    client, access_token = authenticated_client
    
    chat_messages = create_chat_messages(test_user.id)
    
    for msg in chat_messages:
        test_db.add(msg)
    await test_db.commit()
    
    id_to_delete = str(chat_messages[0].id)
    
    response = await client.delete(
        f"/api/v1/chat/{id_to_delete}",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 204
    
    query = select(ChatMessage).where(ChatMessage.id == uuid.UUID(id_to_delete))
    result = await test_db.execute(query)
    message = result.scalars().first()
    
    assert message is None

@pytest.mark.asyncio
async def test_delete_message_unauthorized(client):
    """Test that the chat messages endpoint returns 403 without token."""
    response = await client.delete(
        "/api/v1/chat/msg1",
    )
    
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_delete_message_not_found(authenticated_client, test_user):
    """Test that the chat messages endpoint returns 404 if the message is not found."""
    
    client, access_token = authenticated_client
    
    response = await client.delete(
        "/api/v1/chat/00000000-0000-0000-0000-000000000000",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 404
    assert response.json()["detail"] == "Message not found"

@pytest.mark.asyncio
async def test_create_message(authenticated_client, test_user, mock_gemini_messages_generator, mock_gemini_embeddings):
    """Test that the chat messages endpoint returns a valid response for a valid request."""
    
    client, access_token = authenticated_client
    
    payload = CreateMessageRequest(messages_list=[CreateMessageRequestItem(message="Explain flush, await, fresh in sqlalchemy", datetime=datetime.now())])
    
    response = await client.post(
        "/api/v1/chat",
        json=payload.model_dump(mode='json'),
        headers={"Authorization": f"Bearer {access_token}"}
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
        json=payload.model_dump(mode='json'),
    )
    
    assert response.status_code == 403
