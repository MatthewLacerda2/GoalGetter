"""The seven embedding columns, as one table the backfill walks (#96).

Five tables, seven columns, one shape: *where the rows come from*, *which
attribute is null*, and *what text that attribute is an embedding of*. Written
as data rather than as seven functions because that is what it is - the job in
`embeddings.py` has one piece of logic and it should not be copied seven times.

The text is a callable, not an attribute name, because two of the seven are not
a plain column read: a tutor reply is an array of chat bubbles, and a goal's
description may be absent entirely.

**Adding a column here is the whole change.** A new embedding column needs an
entry and a `list_missing_embeddings` on its repository; nothing in the job
knows how many there are.
"""

from collections.abc import Callable
from dataclasses import dataclass
from typing import Any

from backend.repositories.chat_message_repository import ChatMessageRepository
from backend.repositories.goal_repository import GoalRepository
from backend.repositories.question_repository import QuestionRepository
from backend.repositories.resource_repository import ResourceRepository
from backend.repositories.student_context_repository import StudentContextRepository


@dataclass(frozen=True)
class EmbeddingColumn:
    """One nullable vector column and the text it is an embedding of."""

    attribute: str
    text: Callable[[Any], str | None]


@dataclass(frozen=True)
class EmbeddingSource:
    """One table: the repository that lists its unembedded rows, and its columns.

    The repository is the class, not an instance - the job holds the session
    and builds one per run, the way every other job does.
    """

    table: str
    repository: type
    columns: tuple[EmbeddingColumn, ...]


def _tutor_reply(row) -> str:
    """The tutor's reply as one text. It is stored as the array of chat bubbles
    the screen draws; what it *says* is the bubbles read in order."""
    return " ".join(row.tutor_responses or ())


SOURCES: tuple[EmbeddingSource, ...] = (
    EmbeddingSource(
        "chat_messages",
        ChatMessageRepository,
        (
            EmbeddingColumn("prompt_embedding", lambda row: row.prompt),
            EmbeddingColumn("tutor_response_embedding", _tutor_reply),
        ),
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
