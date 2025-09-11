from pydantic import BaseModel, Field, field_validator, ConfigDict

class OAuth2Request(BaseModel):
    access_token: str = Field(..., description="Google OAuth2 access token")

class StudentResponse(BaseModel):
    id: str
    email: str
    google_id: str
    goal_name: str
    name: str
    current_streak: int
    overall_xp: int

    model_config = ConfigDict(from_attributes=True)

class TokenResponse(BaseModel):
    access_token: str = Field(..., description="JWT access token")
    token_type: str = Field(default="bearer", description="Type of token")
    student: StudentResponse    
    
    @field_validator('token_type')
    @classmethod
    def validate_token_type(cls, v: str) -> str:
        if v.lower() != 'bearer':
            raise ValueError('token_type must be bearer')
        return v.lower()
