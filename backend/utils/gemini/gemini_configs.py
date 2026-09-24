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

    client = get_client()

    response = client.models.embed_content(
        model=EMBEDDING_MODEL,
        contents=text,
        config=EmbedContentConfig(
            output_dimensionality=NUM_DIMENSIONS,
        ),
    )

    embedding_values = response.embeddings[0].values
    return np.array(embedding_values, dtype=np.float32)
