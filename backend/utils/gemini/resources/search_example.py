from google import genai
from google.genai import types
from backend.core.config import settings

client = genai.Client(api_key=settings.GEMINI_API_KEY)

grounding_tool = types.Tool(
    google_search=types.GoogleSearch()
)

config = types.GenerateContentConfig(
    thinking_config=types.ThinkingConfig(
        thinking_budget=0
    ),
    automatic_function_calling={"disable": True},
    tools=[grounding_tool]
)

response = client.models.generate_content(
    model="gemini-2.5-pro",
    contents="Did you see the paypackage for Elon Musk? Be brief and to the point.",
    config=config,
)

print(response)