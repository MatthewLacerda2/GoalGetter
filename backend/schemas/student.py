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
    
class StudentCurrentStatusResponse(BaseModel):
    student_id: str
    student_name: str
    student_email: str
    overall_xp: int
    goal_id: str
    goal_name: str
    current_streak: int