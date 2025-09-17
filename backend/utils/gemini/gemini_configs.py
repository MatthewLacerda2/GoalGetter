import logging
import numpy as np
from dotenv import load_dotenv
from typing import Any
from google.genai import Client
from google.genai.types import GenerateContentConfig, EmbedContentConfig
from backend.core.config import settings
from backend.utils.envs import NUM_DIMENSIONS

logger = logging.getLogger(__name__)
load_dotenv()

def get_client():
    return Client(api_key=settings.GEMINI_API_KEY)

def get_gemini_flash_config(json_schema: dict[str, Any]) -> GenerateContentConfig:
    return GenerateContentConfig(
        response_mime_type='application/json',
        automatic_function_calling={"disable": True},
        response_schema=json_schema
    )

def get_gemini_flash_config_plain_text() -> GenerateContentConfig:
    return GenerateContentConfig(
        response_mime_type='plain/text',
        automatic_function_calling={"disable": True}
    )

def get_gemini_pro_config(json_schema: dict[str, Any]) -> GenerateContentConfig:
    return GenerateContentConfig(
    response_mime_type='application/json',
    automatic_function_calling={"disable": True},
    response_schema=json_schema
)

def get_gemini_pro_config_plain_text() -> GenerateContentConfig:
    return GenerateContentConfig(
        response_mime_type='plain/text',
        automatic_function_calling={"disable":True}
    )

def get_gemini_embeddings(text: str) -> np.ndarray:
    
    client = get_client()
    
    response = client.models.embed_content(
        model="gemini-embedding-001",
        contents=text,
        config=EmbedContentConfig(
            output_dimensionality=NUM_DIMENSIONS,
        ),
    )
    
    embedding_values = response.embeddings[0].values
    return np.array(embedding_values, dtype=np.float32)