from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class TutorMessageRequest(BaseModel):
    """POST /tutor/messages: what the student says to the tutor."""
    message: str = Field(..., min_length=1, description="The student's message")


class ChatExchange(BaseModel):
    """One exchange: the student's prompt and the tutor's reply bubbles. The
    client renders it as one user bubble plus one tutor bubble per response."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    prompt: str = Field(..., description="What the student sent")
    responses: list[str] = Field(..., validation_alias="tutor_responses", description="The tutor's reply, one bubble per string")
    is_liked: bool = Field(..., description="Whether the student liked the reply")
    created_at: datetime = Field(..., description="The pagination cursor (`before`)")


class LikeRequest(BaseModel):
    """PUT /tutor/messages/{id}/like: set (not toggle) the like on a reply."""
    is_liked: bool
