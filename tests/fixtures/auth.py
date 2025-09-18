import pytest
from unittest.mock import patch

@pytest.fixture
def mock_google_verify():
    """Fixture to mock Google token verification"""
    from google.oauth2 import id_token
    
    def mock_verify_oauth2_token(token, request, client_id):
        if token == "valid_google_token":
            return {
                "iss": "accounts.google.com",
                "sub": "12345",
                "email": "test1@example.com",
                "email_verified": True,
                "name": "Test User 1",
                "aud": client_id
            }
        elif token == "fixture_user_token":
            return {
                "iss": "accounts.google.com",
                "sub": "test_google_id_123",
                "email": "test@example.com",
                "email_verified": True,
                "name": "Test User",
                "aud": client_id
            }
        raise ValueError("Invalid token")

    with patch('google.oauth2.id_token.verify_oauth2_token', side_effect=mock_verify_oauth2_token) as mock:
        yield mock
