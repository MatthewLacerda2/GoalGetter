from dotenv import load_dotenv
from google.genai import Client
from google.genai.types import GenerateContentConfig, ThinkingConfig
import logging
from backend.core.config import settings
from typing import Any

logger = logging.getLogger(__name__)
load_dotenv()

def get_client():
    return Client(api_key=settings.GEMINI_API_KEY)

def get_gemini_flash_config(json_schema: dict[str, Any]) -> GenerateContentConfig:
    return GenerateContentConfig(
        response_mime_type='application/json',
        thinking_config=ThinkingConfig(
            thinking_budget=0
        ),
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