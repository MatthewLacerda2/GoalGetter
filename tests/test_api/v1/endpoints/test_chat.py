import pytest
from sqlalchemy import select
from backend.schemas.chat_message import ChatMessageResponse, ChatMessageItem, LikeMessageRequest, CreateMessageResponse, CreateMessageRequest, EditMessageRequest
from backend.models.chat_message import ChatMessage
from datetime import datetime

def create_chat_messages(user_id: str):
    """Create a predefined array of chat messages for testing"""
    
    messages = []
    for i in range(15):
        msg = ChatMessage(
            id=f"msg{i}",
            message=f"Message {i}",
            sender_id=user_id,
            array_id="array1",
            num_tokens=3,
            created_at=datetime.now(),
            student_id=user_id
        )
        messages.append(msg)
    return messages

@pytest.mark.asyncio
async def test_get_chat_messages_with_parameters(client, mock_google_verify, test_db, test_user):
    """Test that the chat messages endpoint returns a valid response for a valid request."""
    
    mock_google_verify.return_value = {
        'email': test_user.email,
        'sub': test_user.google_id,
        'name': test_user.name
    }
    
    login_response = await client.post(
        "/api/v1/auth/login",
        json={"access_token": "fixture_user_token"}
    )
    access_token = login_response.json()["access_token"]
    
    chat_messages = create_chat_messages(test_user.id)
    
    for msg in chat_messages:
        test_db.add(msg)
    await test_db.commit()
    
    limit = 10
    
    response = await client.get(
        "/api/v1/chat",
        headers={"Authorization": f"Bearer {access_token}"},
        params={"message_id": "msg1", "limit": limit}
    )
    
    chat_response = ChatMessageResponse.model_validate(response.json())
    
    assert response.status_code == 200
    assert isinstance(chat_response, ChatMessageResponse)
    assert len(chat_response.messages) == limit

@pytest.mark.asyncio
async def test_get_chat_messages_no_parameters(client, mock_google_verify, test_db, test_user):
    """Test that the chat messages endpoint works with no optional parameters."""
    
    mock_google_verify.return_value = {
        'email': test_user.email,
        'sub': test_user.google_id,
        'name': test_user.name
    }
    
    login_response = await client.post(
        "/api/v1/auth/login",
        json={"access_token": "fixture_user_token"}
    )
    access_token = login_response.json()["access_token"]
    
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
async def test_like_message_not_found(client, mock_google_verify, test_db, test_user):
    """Test that the chat messages endpoint returns 404 if the message is not found."""
    
    mock_google_verify.return_value = {
        'email': test_user.email,
        'sub': test_user.google_id,
        'name': test_user.name
    }
    
    login_response = await client.post(
        "/api/v1/auth/login",
        json={"access_token": "fixture_user_token"}
    )
    access_token = login_response.json()["access_token"]
    
    payload = LikeMessageRequest(message_id="non_existent_id", like=True)
    
    response = await client.patch(
        "/api/v1/chat/likes",
        json=payload.model_dump(),
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 404
    assert response.json()["detail"] == "Message not found"

@pytest.mark.asyncio
async def test_like_message(client, mock_google_verify, test_db, test_user):
    """Test that the chat messages endpoint returns a valid response for a valid request."""
    
    mock_google_verify.return_value = {
        'email': test_user.email,
        'sub': test_user.google_id,
        'name': test_user.name
    }
    
    login_response = await client.post(
        "/api/v1/auth/login",
        json={"access_token": "fixture_user_token"}
    )
    access_token = login_response.json()["access_token"]
    
    chat_messages = create_chat_messages(test_user.id)
    
    for msg in chat_messages:
        test_db.add(msg)
    await test_db.commit()
    
    payload = LikeMessageRequest(message_id=chat_messages[0].id, like=True)
    
    response = await client.patch(
        "/api/v1/chat/likes",
        json=payload.model_dump(),
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    chat_response = ChatMessageItem.model_validate(response.json())
    
    assert response.status_code == 200
    assert isinstance(chat_response, ChatMessageItem)
    assert chat_response.is_liked == payload.like
    assert chat_response.id == chat_messages[0].id
    assert chat_response.sender_id == chat_messages[0].sender_id
    assert chat_response.message == chat_messages[0].message
    assert chat_response.created_at == chat_messages[0].created_at
    
@pytest.mark.asyncio
async def test_edit_message(client, mock_google_verify, test_db, test_user):
    """Test that the chat messages endpoint returns a valid response for a valid request."""
    
    mock_google_verify.return_value = {
        'email': test_user.email,
        'sub': test_user.google_id,
        'name': test_user.name
    }
    
    login_response = await client.post(
        "/api/v1/auth/login",
        json={"access_token": "fixture_user_token"}
    )
    access_token = login_response.json()["access_token"]
    
    chat_messages = create_chat_messages(test_user.id)
    
    for msg in chat_messages:
        test_db.add(msg)
    await test_db.commit()
    
    payload = EditMessageRequest(message_id=chat_messages[0].id, message="Edited message")
    
    response = await client.patch(
        "/api/v1/chat/edit",
        json=payload.model_dump(),
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    chat_response = ChatMessageItem.model_validate(response.json())
    
    assert response.status_code == 200
    assert isinstance(chat_response, ChatMessageItem)
    assert chat_response.is_liked == chat_messages[0].is_liked
    assert chat_response.id == chat_messages[0].id
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
async def test_edit_message_not_found(client, mock_google_verify, test_db, test_user):

    """Test that the chat messages endpoint returns 404 if the message is not found."""
    
    mock_google_verify.return_value = {
        'email': test_user.email,
        'sub': test_user.google_id,
        'name': test_user.name
    }

    login_response = await client.post(
        "/api/v1/auth/login",
        json={"access_token": "fixture_user_token"}
    )
    access_token = login_response.json()["access_token"]
    
    payload = EditMessageRequest(message_id="non_existent_id", message="Edited message")
    
    response = await client.patch(
        "/api/v1/chat/edit",
        json=payload.model_dump(),
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 404
    assert response.json()["detail"] == "Message not found"

@pytest.mark.asyncio
async def test_delete_message(client, mock_google_verify, test_db, test_user):
    """Test that the chat messages endpoint returns a valid response for a valid request."""
    
    mock_google_verify.return_value = {
        'email': test_user.email,
        'sub': test_user.google_id,
        'name': test_user.name
    }
    
    login_response = await client.post( 
        "/api/v1/auth/login",
        json={"access_token": "fixture_user_token"}
    )
    access_token = login_response.json()["access_token"]
    
    chat_messages = create_chat_messages(test_user.id)
    
    for msg in chat_messages:
        test_db.add(msg)
    await test_db.commit()
    
    id_to_delete = chat_messages[0].id
    
    response = await client.delete(
        f"/api/v1/chat/{id_to_delete}",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 204
    
    query = select(ChatMessage).where(ChatMessage.id == id_to_delete)
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
async def test_delete_message_not_found(client, mock_google_verify, test_db, test_user):
    """Test that the chat messages endpoint returns 404 if the message is not found."""
    
    mock_google_verify.return_value = {
        'email': test_user.email,
        'sub': test_user.google_id,
        'name': test_user.name
    }
    
    login_response = await client.post(
        "/api/v1/auth/login",
        json={"access_token": "fixture_user_token"}
    )
    access_token = login_response.json()["access_token"]
    
    response = await client.delete(
        "/api/v1/chat/non_existent_id",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 404
    assert response.json()["detail"] == "Message not found"

@pytest.mark.asyncio
async def test_create_message(client, mock_google_verify, test_db, test_user):
    """Test that the chat messages endpoint returns a valid response for a valid request."""
    
    mock_google_verify.return_value = {
        'email': test_user.email,
        'sub': test_user.google_id,
        'name': test_user.name
    }
    
    login_response = await client.post(
        "/api/v1/auth/login",
        json={"access_token": "fixture_user_token"}
    )
    access_token = login_response.json()["access_token"]
    
    payload = CreateMessageRequest(message="Test message")
    
    response = await client.post(
        "/api/v1/chat",
        json=payload.model_dump(),
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    chat_response = CreateMessageResponse.model_validate(response.json())
    
    assert response.status_code == 201
    assert isinstance(chat_response, CreateMessageResponse)
    assert len(chat_response.messages) > 0

@pytest.mark.asyncio
async def test_create_message_unauthorized(client):
    """Test that the chat messages endpoint returns 403 without token."""
    response = await client.post(
        "/api/v1/chat",
        json={"message": "Test message"}
    )
    
    assert response.status_code == 403