import asyncio
import logging
from dataclasses import dataclass

import numpy as np

# Re-exported: `make gemini` and the live suite wrap it here (see get_client).
from google.genai import Client as Client
from google.genai.types import Content, EmbedContentConfig, GenerateContentConfig, Part, Tool
from numpy.typing import NDArray
from pydantic import BaseModel

from backend.core.config import settings
from backend.core.vectors import NUM_DIMENSIONS
from backend.services.gemini.client.gemini_retry import call_with_retry

logger = logging.getLogger(__name__)

# The model that writes every stored vector. A constant beside the call rather
# than a setting (#215): each vector column holds this model's vectors at
# NUM_DIMENSIONS, and a different model is a different space - comparing its
# vectors with the ones already stored would be meaningless, so changing it
# means re-embedding every row, not editing an environment variable.
EMBEDDING_MODEL = "gemini-embedding-2"


@dataclass
class _Shared:
    loop: asyncio.AbstractEventLoop | None = None
    client: Client | None = None


_shared = _Shared()


def get_client() -> Client:
    """The one Gemini client, reused by every call.

    One per event loop, not one per process: the SDK's async side keeps an
    httpx connection pool, and a pool opened on one loop cannot be used from
    another. The server and the nightly run each have a single loop, so there
    it is one client for good; a test or `make gemini` that starts a new loop
    gets a new one. It is held here because a `Client` nobody holds a name to
    is garbage-collected mid-call, closing the connection under it (seen on the
    preview, 2026-09-26).

    `Client` is resolved from this module at call time, which is what the live
    suite and `make gemini` wrap to count and record every call.
    """
    loop = asyncio.get_running_loop()
    if _shared.loop is not loop or _shared.client is None:
        _shared.loop, _shared.client = loop, Client(api_key=settings.GEMINI_API_KEY)
    return _shared.client


def get_gemini_config(schema: type[BaseModel]) -> GenerateContentConfig:
    """JSON generation, held to `schema`'s JSON schema."""
    return GenerateContentConfig(
        response_mime_type="application/json",
        response_schema=schema.model_json_schema(),
    )


def get_gemini_config_plain_text(tools: list[Tool] | None = None) -> GenerateContentConfig:
    """Plain-text generation. `tools` wires Gemini's own tools, e.g. Google Search."""
    return GenerateContentConfig(
        response_mime_type="text/plain",
        tools=[*tools] if tools else None,
    )


async def get_gemini_embeddings(text: str) -> NDArray[np.float32]:

    return (await get_gemini_embeddings_batch([text]))[0]


async def get_gemini_embeddings_batch(texts: list[str]) -> list[NDArray[np.float32]]:
    """Embed many texts in one request - what the nightly backfill spends.

    `embed_content` takes a list and answers a list in the same order, so N
    texts cost one round trip instead of N. That is the "batch mode" the
    backfill was asked for: the caller chunks its queue
    (`EMBEDDING_BATCH_SIZE`) and every chunk is a single billed call.

    Not Gemini's asynchronous Batch API. That one is cheaper again, but it
    answers hours later through a job handle somebody has to remember, and
    remembering means a column the schema does not have. A backfill that runs
    every night at midnight already has all the time it needs; what it cannot
    have is state it has nowhere to store.

    One billed call, so it goes through `call_with_retry` like every generation:
    the deadline and the retries are the caller's budget
    (`run_gemini_background`).
    """
    client = get_client()

    # One Content per text, never the bare strings. From google-genai 2.x on, a
    # `gemini-embedding-2` model reads a list of strings as the parts of ONE
    # multimodal content and answers ONE aggregated vector for all of them (#163).
    response = await call_with_retry(
        lambda: client.aio.models.embed_content(
            model=EMBEDDING_MODEL,
            contents=[Content(parts=[Part(text=text)]) for text in texts],
            config=EmbedContentConfig(output_dimensionality=NUM_DIMENSIONS),
        ),
        "embed_content",
    )

    # No embeddings at all is a short answer, which the caller already refuses.
    embeddings = response.embeddings or []
    return [np.array(embedding.values, dtype=np.float32) for embedding in embeddings]
