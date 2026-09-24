import logging
from typing import Any

import numpy as np
from dotenv import load_dotenv
from google.genai import Client
from google.genai.types import EmbedContentConfig, GenerateContentConfig, Tool

from backend.core.config import settings
from backend.utils.envs import EMBEDDING_MODEL, NUM_DIMENSIONS

logger = logging.getLogger(__name__)
load_dotenv()


def get_client():
    return Client(api_key=settings.GEMINI_API_KEY)


def get_gemini_config(json_schema: dict[str, Any]) -> GenerateContentConfig:
    return GenerateContentConfig(
        response_mime_type="application/json",
        response_schema=json_schema,
    )


def get_gemini_config_plain_text(tools: list[Tool] | None = None) -> GenerateContentConfig:
    """Plain-text generation. `tools` wires Gemini's own tools, e.g. Google Search."""
    return GenerateContentConfig(
        response_mime_type="text/plain",
        tools=tools,
    )


def get_gemini_embeddings(text: str) -> np.ndarray:

    return get_gemini_embeddings_batch([text])[0]


def get_gemini_embeddings_batch(texts: list[str]) -> list[np.ndarray]:
    """Embed many texts in one request - what the nightly backfill spends (#96).

    `embed_content` takes a list and answers a list in the same order, so N
    texts cost one round trip instead of N. That is the "batch mode" the
    backfill was asked for: the caller chunks its queue
    (`EMBEDDING_BATCH_SIZE`) and every chunk is a single billed call.

    Not Gemini's asynchronous Batch API. That one is cheaper again, but it
    answers hours later through a job handle somebody has to remember, and
    remembering means a column - which #96 explicitly does not create. A
    backfill that runs every night at midnight already has all the time it
    needs; what it cannot have is state it is not allowed to store.

    Blocking, like every other call in this module: reach it through
    `run_gemini_background`, which runs it off the event loop and retries.
    """
    client = get_client()

    response = client.models.embed_content(
        model=EMBEDDING_MODEL,
        contents=texts,
        config=EmbedContentConfig(
            output_dimensionality=NUM_DIMENSIONS,
        ),
    )

    return [np.array(embedding.values, dtype=np.float32) for embedding in response.embeddings]
