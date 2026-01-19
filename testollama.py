import ollama
from ollama._types import ResponseError

gemini = "gemini-3-pro-preview"
qwen3 = "qwen3-vl:235b-cloud"
deep = "deepseek-v3.1:671b-cloud"
gpt = "gpt-oss:120b-cloud"

model = gpt

try:
    response: ollama.ChatResponse = ollama.chat(
        model=model,
        stream=False,
        messages=[
            {
                "role": "user",
                "content": "Who are you?"
            }
        ],
        think=False
    )
    print(response)
except ResponseError as e:
    print(f"Error {e.status_code}: {str(e)}")
except Exception as e:
    print(f"Unexpected error: {type(e).__name__}: {e}")