"""Real API responses, captured once and replayed (#175, #176).

`responses/grounded_response.json` is one Gemini call with the Google Search
tool and `responses/youtube_search.json` one YouTube `search.list`, both taken
2026-09-26 with the user's permission - no key, no headers. They are the shape
the code must read, rather than a shape a test author imagined.

`web_client` stands in for the internet: a real `httpx.AsyncClient` whose
transport answers from a table, so redirects are followed by httpx itself and
no socket is ever opened.
"""

import json
from pathlib import Path

import httpx
from google.genai import types

RESPONSES = Path(__file__).parent / "responses"


def grounded_response() -> types.GenerateContentResponse:
    raw = json.loads((RESPONSES / "grounded_response.json").read_text())
    return types.GenerateContentResponse.model_validate(raw)


def youtube_search() -> dict:
    return json.loads((RESPONSES / "youtube_search.json").read_text())


def web_client(pages: dict[str, httpx.Response | str], log: list | None = None):
    """An AsyncClient over a table of URL -> answer. A string answer is a
    redirect to that URL; a URL missing from the table refuses the connection."""

    def answer(request: httpx.Request) -> httpx.Response:
        if log is not None:
            log.append(request)
        found = pages.get(str(request.url).split("?")[0])
        if found is None:
            raise httpx.ConnectError("no such host", request=request)
        if isinstance(found, str):
            return httpx.Response(302, headers={"location": found})
        return found

    return httpx.AsyncClient(transport=httpx.MockTransport(answer))
