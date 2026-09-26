"""From the captured grounded response to stored links, with the web mocked (#175).

The measure the issue asks for: of the response's eight grounding sources, which
become resources, and that every one is a real page's address - never the
redirect, never a URL the model wrote.
"""

import re

import httpx
import pytest

from backend.services.resources.link_validation import validate_resources
from backend.tests.fixtures.captured import grounded_response, web_client
from backend.tests.test_services.test_resource_search import described, run


@pytest.mark.asyncio
async def test_the_captured_sources_become_the_pages_they_redirect_to():
    sources = grounded_response().candidates[0].grounding_metadata.grounding_chunks
    landing = {c.web.uri: f"https://{c.web.title}/page{n}" for n, c in enumerate(sources)}
    found, _ = run(described(*((n, "webpage") for n in range(3)), *((n, "pdf") for n in (3, 4))))
    # Where each redirect lands: pages, one page that is gone, one real PDF.
    web = {**landing, **{final: httpx.Response(200) for final in landing.values()}}
    web[landing[sources[1].web.uri]] = httpx.Response(404)
    web[landing[sources[3].web.uri]] = httpx.Response(
        200, headers={"content-type": "application/pdf"}
    )

    kept = await validate_resources(found.pages, client=web_client(web))

    assert [r.link for r in kept] == [
        "https://chess.com/page0",
        "https://chess.com/page2",
        "https://google.com/page3",
    ]
    written = set(re.findall(r"https?://[^\s)\]]+", grounded_response().text))
    assert not {r.link for r in kept} & written
