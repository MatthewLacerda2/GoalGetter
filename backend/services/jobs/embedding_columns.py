"""The eight embedding columns, as one table the backfill walks (#96).

Six tables, eight columns, one shape: *where the rows come from*, *which
attribute is null*, and *what text that attribute is an embedding of*. Written
as data rather than as seven functions because that is what it is - the job in
`embeddings.py` has one piece of logic and it should not be copied seven times.

The text is a callable, not an attribute name, because two of the eight are not
a plain column read: a tutor reply is an array of chat bubbles, and a goal's
description may be absent entirely.

**Adding a column here is the whole change.** A new embedding column needs an
entry and a `list_missing_embeddings` on its repository; nothing in the job
knows how many there are.
"""

from collections.abc import Callable
from dataclasses import dataclass
from typing import Protocol

from sqlalchemy.ext.asyncio import AsyncSession

from backend.models.base import Base
from backend.models.chat_message import ChatMessage
from backend.repositories.chat_message_repository import ChatMessageRepository
from backend.repositories.frontier_repository import FrontierRepository
from backend.repositories.goal_repository import GoalRepository
from backend.repositories.question_repository import QuestionRepository
from backend.repositories.resource_repository import ResourceRepository
from backend.repositories.student_context_repository import StudentContextRepository


class EmbeddingRepository[M: Base](Protocol):
    """What the backfill needs of a table's repository: its unembedded rows, and
    a way to write one back."""

    async def list_missing_embeddings(self, limit: int) -> list[M]: ...

    async def update(self, entity: M) -> M: ...


@dataclass(frozen=True)
class EmbeddingColumn[M: Base]:
    """One nullable vector column and the text it is an embedding of."""

    attribute: str
    text: Callable[[M], str | None]


@dataclass(frozen=True)
class EmbeddingSource[M: Base]:
    """One table: the repository that lists its unembedded rows, and its columns.

    The repository is the class, not an instance - the job holds the session
    and builds one per run, the way every other job does.
    """

    table: str
    repository: Callable[[AsyncSession], EmbeddingRepository[M]]
    columns: tuple[EmbeddingColumn[M], ...]


def _tutor_reply(row: ChatMessage) -> str:
    """The tutor's reply as one text. It is stored as the array of chat bubbles
    the screen draws; what it *says* is the bubbles read in order."""
    return " ".join(row.tutor_responses or ())


# Each entry's model is its repository's, so every `text` is checked against
# the columns that model really has.
SOURCES = (
    EmbeddingSource(
        "chat_messages",
        ChatMessageRepository,
        (
            EmbeddingColumn("prompt_embedding", lambda row: row.prompt),
            EmbeddingColumn("tutor_response_embedding", _tutor_reply),
        ),
    ),
    EmbeddingSource(
        "frontiers",
        FrontierRepository,
        (EmbeddingColumn("definition_embedding", lambda row: row.definition),),
    ),
    EmbeddingSource(
        "goals",
        GoalRepository,
        (EmbeddingColumn("description_embedding", lambda row: row.description),),
    ),
    EmbeddingSource(
        "resources",
        ResourceRepository,
        (EmbeddingColumn("description_embedding", lambda row: row.description),),
    ),
    EmbeddingSource(
        "questions",
        QuestionRepository,
        (EmbeddingColumn("text_embedding", lambda row: row.text),),
    ),
    EmbeddingSource(
        "student_contexts",
        StudentContextRepository,
        (
            EmbeddingColumn("state_embedding", lambda row: row.state),
            EmbeddingColumn("metacognition_embedding", lambda row: row.metacognition),
        ),
    ),
)
