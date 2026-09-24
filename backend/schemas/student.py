from pydantic import BaseModel, ConfigDict, Field


class OAuth2Request(BaseModel):
    access_token: str = Field(..., description="Google OAuth2 access token")


class StudentResponse(BaseModel):
    id: str
    google_id: str
    email: str
    name: str

    model_config = ConfigDict(from_attributes=True)


class TokenResponse(BaseModel):
    access_token: str = Field(..., description="JWT access token")
    refresh_token: str = Field(..., description="Rotated long-lived refresh token")
    student: StudentResponse


class TokenRefreshRequest(BaseModel):
    refresh_token: str = Field(..., description="Active refresh token")


class TokenRefreshResponse(BaseModel):
    access_token: str = Field(..., description="New JWT access token")
    refresh_token: str = Field(..., description="New rotated refresh token")


class DevLoginRequest(BaseModel):
    """Dev-only fictitious sign-in (POST /auth/dev-login). The name is the only
    input: the stored name, email and google_id are all derived from it."""

    name: str = Field(
        ...,
        min_length=1,
        max_length=40,
        pattern=r"[A-Za-z0-9]",
        description="Display name; stored as 'Fictitious <name>'",
    )
