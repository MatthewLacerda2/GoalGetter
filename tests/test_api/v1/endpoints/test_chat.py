import pytest
from backend.schemas.chat_message import ChatMessageResponse
from backend.models.chat_message import ChatMessage
from datetime import datetime

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
    
    chat_messages = [
        ChatMessage(
            id="msg1",
            message="Hello, how are you?",
            sender_id="user",
            array_id="array1",
            num_tokens=4,
            created_at=datetime.now(),
            is_modern=False,
            student_id=test_user.id
        ),
        ChatMessage(
            id="msg2", 
            message="Waddaya doin'?",
            sender_id="user",
            array_id="array2",
            num_tokens=5,
            created_at=datetime.now(),
            is_modern=True,
            student_id=test_user.id
        )
    ]
    
    for msg in chat_messages:
        test_db.add(msg)
    await test_db.commit()
    
    response = await client.get(
        "/api/v1/chat",
        headers={"Authorization": f"Bearer {access_token}"},
        params={"message_id": "msg1", "limit": 10}
    )
    
    chat_response = ChatMessageResponse.model_validate(response.json())
    
    assert response.status_code == 200
    assert isinstance(chat_response, ChatMessageResponse)
    assert len(chat_response.messages) == 2

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
    
    for i in range(15):
        msg = ChatMessage(
            id=f"msg{i}",
            message=f"Message {i}",
            sender_id="user",
            array_id="array1",
            num_tokens=3,
            created_at=datetime.now(),
            is_modern=False,
            student_id=test_user.id
        )
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
    """Test that the chat messages endpoint returns 401 without token."""
    response = await client.get(
        "/api/v1/chat",
        params={"message_id": "msg1", "limit": 10}
    )
    
    assert response.status_code == 401

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