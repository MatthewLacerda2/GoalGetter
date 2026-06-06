import pytest
from unittest.mock import patch
from backend.utils.envs import GOOGLE_CLIENT_ID

@pytest.fixture
def mock_google_verify():
    """Fixture to mock Google token verification"""
    # By default, mock verify_oauth2_token to return the default test user profile.
    # This can be overridden per test using mock_google_verify.return_value or side_effect.
    default_profile = {
        "iss": "accounts.google.com",
        "sub": "test_google_id_123",
        "email": "test@example.com",
        "email_verified": True,
        "name": "Test User",
        "aud": GOOGLE_CLIENT_ID
    }

    with patch('google.oauth2.id_token.verify_oauth2_token', return_value=default_profile) as mock:
        yield mock
