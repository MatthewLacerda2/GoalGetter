import httpx
import pytest

from backend.models.resource import Resource, StudyResourceType
from backend.services.resources.link_validation import validate_resources
from backend.tests.fixtures.captured import web_client

MODULE = "backend.services.resources.link_validation"
REDIRECT = "https://vertexaisearch.cloud.google.com/grounding-api-redirect/"
LESSONS = "https://www.chess.com/pt-BR/lessons"
PDF = StudyResourceType.pdf


class FakeResponse:
    def __init__(self, status_code=200, headers=None, payload=None):
        self.status_code = status_code
        self.headers = headers or {}
        self._payload = payload or {}

    def json(self):
        return self._payload


class FakeClient:
    """Serves canned responses keyed by a substring of the requested URL."""

    def __init__(self, routes):
        self.routes = routes
        self.calls = []

    async def get(self, url, params=None, **kwargs):
        self.calls.append((url, params))
        for fragment, response in self.routes.items():
            if fragment in url:
                if isinstance(response, Exception):
                    raise response
                return response
        return FakeResponse(status_code=404)


def make(resource_type, link):
    return Resource(
        goal_id="00000000-0000-0000-0000-000000000001",
        resource_type=resource_type,
        name="n",
        description="d",
        language="en",
        link=link,
    )


def pages(*links, kind=StudyResourceType.webpage):
    return [make(kind, link) for link in links]


@pytest.mark.asyncio
async def test_a_google_redirect_is_stored_as_the_page_it_lands_on():
    """The grounding source is a redirect; the resource keeps the real address"""
    (page,) = pages(REDIRECT + "abc")
    client = web_client({REDIRECT + "abc": LESSONS, LESSONS: httpx.Response(200)})

    assert await validate_resources([page], client=client) == [page]
    assert page.link == LESSONS


@pytest.mark.asyncio
async def test_only_a_page_that_is_gone_is_dropped():
    """404 and 410 go; a 403 bot wall is a page that exists, and stays"""
    gone, removed, walled, broken = pages(*(REDIRECT + n for n in "abcd"))
    client = web_client(
        {
            REDIRECT + "a": "https://a.dev/x",
            "https://a.dev/x": httpx.Response(404),
            REDIRECT + "b": "https://b.dev/x",
            "https://b.dev/x": httpx.Response(410),
            REDIRECT + "c": "https://c.dev/x",
            "https://c.dev/x": httpx.Response(403),
            REDIRECT + "d": "https://d.dev/x",
        }
    )

    kept = await validate_resources([gone, removed, walled, broken], client=client)

    assert kept == [walled]
    assert walled.link == "https://c.dev/x"


@pytest.mark.asyncio
async def test_a_redirect_that_stays_on_google_is_never_stored():
    (page,) = pages(REDIRECT + "abc")
    client = web_client({REDIRECT + "abc": httpx.Response(200)})

    assert await validate_resources([page], client=client) == []


@pytest.mark.asyncio
async def test_pdf_must_really_be_a_pdf():
    """An HTML page pretending to be an ebook is dropped; a real PDF, or a
    .pdf behind a bot wall, is kept"""
    real, walled, fake = pages("https://h.dev/r", "https://h.dev/w", "https://h.dev/f", kind=PDF)
    client = web_client(
        {
            "https://h.dev/r": httpx.Response(200, headers={"content-type": "application/pdf"}),
            "https://h.dev/w": "https://h.dev/book.pdf",
            "https://h.dev/book.pdf": httpx.Response(403, headers={"content-type": "text/html"}),
            "https://h.dev/f": httpx.Response(200, headers={"content-type": "text/html"}),
        }
    )

    assert await validate_resources([real, walled, fake], client=client) == [real, walled]
    assert walled.link == "https://h.dev/book.pdf"
