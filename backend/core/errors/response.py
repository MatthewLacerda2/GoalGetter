from pydantic import BaseModel, Field

from backend.core.errors.codes import ErrorCode


class ErrorResponse(BaseModel):
    """The body of every error the API answers (#214)."""

    code: ErrorCode = Field(description="What went wrong. The app switches on this.")
    detail: str = Field(description="The same, in English, for a person reading a log.")


# Declared for every route under /api/v1 (`main.py`): any 4xx or 5xx is this
# body. Ranges rather than a status per route, because every route can answer
# a 401, a 422 and a 429 without naming them, and the code is what tells them
# apart. Declaring a 4XX also replaces FastAPI's own 422 schema, which this
# body supersedes (`handlers.py`).
ERROR_RESPONSES: dict[int | str, dict[str, object]] = {
    "4XX": {"model": ErrorResponse, "description": "The request was refused"},
    "5XX": {"model": ErrorResponse, "description": "The server or a service it calls failed"},
}
