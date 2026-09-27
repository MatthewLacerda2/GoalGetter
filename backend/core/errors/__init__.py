"""The API's errors, defined in one place (#214).

- `codes.py` — `ErrorCode`: every error a client can receive, each with its
  HTTP status and default sentence. The one list to read.
- `api_error.py` — `ApiError`, the one exception code raises for them.
- `response.py` — the body every error answers with, and its OpenAPI entry.
- `handlers.py` — turns every exception that reaches FastAPI into that body.

It lives in core/ because every layer that raises (the routes, core's own
token checks, the Gemini client) may import core, and core imports none of them.
"""
