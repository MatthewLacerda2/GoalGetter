import uuid
from datetime import datetime
from typing import Any, ClassVar

import numpy as np
from numpy.typing import NDArray
from pgvector.sqlalchemy import Vector
from sqlalchemy import DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import DeclarativeBase

from backend.core.vectors import NUM_DIMENSIONS

# An embedding column, as the models declare it. pgvector reads a vector back as
# a float32 array, and the code writes one as whatever Gemini returned - a list.
type Embedding = NDArray[np.float32] | list[float]


class Base(DeclarativeBase):
    """Every model's base, and the one place a Python type is given its column type
    (#208). `Mapped[uuid.UUID]` is a Postgres UUID, `Mapped[datetime]` always
    carries its timezone and `Mapped[Embedding]` is a pgvector of the embedding
    model's width, so a model states only what is particular to one column.
    Nullability is the annotation's: `Mapped[str | None]` is NULL-able, `Mapped[str]`
    is NOT NULL."""

    type_annotation_map: ClassVar[dict[Any, Any]] = {
        uuid.UUID: UUID(as_uuid=True),
        datetime: DateTime(timezone=True),
        Embedding: Vector(NUM_DIMENSIONS),
    }
