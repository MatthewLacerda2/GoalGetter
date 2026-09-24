import pytest

from backend.models.resource import Resource, StudyResourceType
from backend.services.resources.link_validation import validate_resources

MODULE = "backend.services.resources.link_validation"


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


@pytest.mark.asyncio
async def test_dead_webpage_is_dropped_live_one_is_kept():
    """A page that 404s is discarded; one that answers survives"""
    alive = make(StudyResourceType.webpage, "https://good.dev/guide")
    dead = make(StudyResourceType.webpage, "https://gone.dev/guide")
    client = FakeClient({"good.dev": FakeResponse(200), "gone.dev": FakeResponse(404)})

    kept = await validate_resources([alive, dead], client=client)

    assert kept == [alive]


@pytest.mark.asyncio
async def test_pdf_must_really_be_a_pdf():
    """An HTML page pretending to be an ebook is dropped; a real PDF is kept"""
    real = make(StudyResourceType.pdf, "https://host.dev/book.pdf")
    fake = make(StudyResourceType.pdf, "https://host.dev/landing-page")
    client = FakeClient(
        {
            "book.pdf": FakeResponse(200, {"content-type": "application/pdf"}),
            "landing-page": FakeResponse(200, {"content-type": "text/html"}),
        }
    )

    kept = await validate_resources([real, fake], client=client)

    assert kept == [real]
