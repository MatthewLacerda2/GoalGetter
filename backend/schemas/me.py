from datetime import datetime

from pydantic import BaseModel, Field


class UserProfile(BaseModel):
    """GET /me: the signed-in student's profile header."""
    id: str
    name: str
    email: str
    member_since: datetime = Field(..., description="students.created_at")
    current_streak: int
