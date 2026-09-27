from backend.core.config import settings
from backend.core.language import Language
from backend.services.gemini.chat.prompt import chat_system_prompt
from backend.services.gemini.chat.schema import (
    GeminiChatMessage,
    GeminiChatResponse,
    StudentContextToChat,
)
from backend.services.gemini.client.gemini_call import generate


async def gemini_messages_generator(
    messages: list[GeminiChatMessage],
    contexts: list[StudentContextToChat],
    goal_name: str,
    goal_description: str,
    language: Language,
) -> GeminiChatResponse:
    # Generate system prompt
    system_instruction = chat_system_prompt(goal_name, goal_description, contexts, language)

    gemini_messages = [{"role": "user", "parts": [{"text": system_instruction}]}]

    for msg in messages:
        role = msg.role if msg.role == "user" else "model"
        gemini_messages.append({"role": role, "parts": [{"text": msg.message}]})

    return await generate(settings.GEMINI_FAST_MODEL, gemini_messages, GeminiChatResponse)
