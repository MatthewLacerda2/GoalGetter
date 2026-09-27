import uuid
from datetime import datetime
from enum import Enum
from typing import TYPE_CHECKING

from sqlalchemy import Enum as SQLEnum
from sqlalchemy import ForeignKey, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.core import clock
from backend.models.base import Base, Embedding

if TYPE_CHECKING:
    from backend.models.goal import Goal


class StudyResourceType(Enum):
    pdf = "pdf"
    webpage = "webpage"
    youtube = "youtube"


class Resource(Base):
    __tablename__ = "resources"
    __table_args__ = (Index("idx_resource_goal_id", "goal_id"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    goal_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("goals.id", ondelete="CASCADE"))
    resource_type: Mapped[StudyResourceType] = mapped_column(SQLEnum(StudyResourceType))
    name: Mapped[str]
    description: Mapped[str]
    language: Mapped[str]
    # Deliberately NOT unique: two students may be recommended the same channel,
    # and sharing/reusing another student's resources is a road we want open.
    link: Mapped[str]
    image_url: Mapped[str | None]
    created_at: Mapped[datetime] = mapped_column(default=clock.now)
    description_embedding: Mapped[Embedding | None]

    goal: Mapped[Goal] = relationship(back_populates="resources")
