from pydantic import BaseModel, Field, ConfigDict

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
    student: StudentResponse