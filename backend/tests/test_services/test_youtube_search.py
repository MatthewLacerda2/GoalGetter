"""Videos come from the YouTube Data API's search, on a captured response (#175)."""

import httpx
import pytest

from backend.core.language import Language
from backend.models.resource import StudyResourceType
from backend.services.resources.youtube_search import search_videos
from backend.tests.fixtures.captured import web_client, youtube_search

MODULE = "backend.services.resources.youtube_search"
GOAL = "00000000-0000-0000-0000-000000000001"
SEARCH = "https://www.googleapis.com/youtube/v3/search"


@pytest.mark.asyncio
async def test_every_video_is_an_id_the_search_returned(monkeypatch):
    monkeypatch.setattr(MODULE + ".YOUTUBE_API_KEY", "test-key")
    asked = []
    client = web_client({SEARCH: httpx.Response(200, json=youtube_search())}, asked)

    videos = await search_videos(client, GOAL, "xadrez para iniciantes", Language.PORTUGUESE)

    ids = [item["id"]["videoId"] for item in youtube_search()["items"]]
    assert [v.link for v in videos] == [f"https://www.youtube.com/watch?v={i}" for i in ids]
    assert videos[0].name == "Xadrez Total | Aprendendo a jogar xadrez"
    assert videos[0].description.startswith("Um video sobre como mover")
    assert {(v.resource_type, v.language) for v in videos} == {(StudyResourceType.youtube, "pt")}
    (request,) = asked
    assert request.url.params["relevanceLanguage"] == "pt"
    assert request.url.params["maxResults"] == "3"


@pytest.mark.asyncio
async def test_a_failed_search_is_no_videos_not_a_failure(monkeypatch):
    monkeypatch.setattr(MODULE + ".YOUTUBE_API_KEY", "test-key")
    quota = web_client({SEARCH: httpx.Response(403, json={"error": {}})})
    down = web_client({})

    assert await search_videos(quota, GOAL, "q", Language.ENGLISH) == []
    assert await search_videos(down, GOAL, "q", Language.ENGLISH) == []


@pytest.mark.asyncio
async def test_no_key_no_search(monkeypatch):
    monkeypatch.setattr(MODULE + ".YOUTUBE_API_KEY", "")
    asked = []

    assert await search_videos(web_client({}, asked), GOAL, "q", Language.ENGLISH) == []
    assert asked == []
