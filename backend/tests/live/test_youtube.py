"""The YouTube Data API, called for real once (#176). SPENDS QUOTA.

A search is the tool that finds videos (CLAUDE.md: Gemini never supplies a
link from memory), and the link validator is what proves a video exists. The
contract between them: an ID `search_videos` returns is one the validator accepts.
"""

import re

import httpx
import pytest

from backend.core.language import Language
from backend.services.resources.link_validation import youtube_picture
from backend.services.resources.youtube_search import search_videos
from backend.tools.gemini_cli import UNSAVED_GOAL_ID

pytestmark = [pytest.mark.live, pytest.mark.usefixtures("youtube_key")]

WATCH = re.compile(r"^https://www\.youtube\.com/watch\?v=[A-Za-z0-9_-]{11}$")


async def test_a_searched_video_id_exists():
    async with httpx.AsyncClient() as client:
        videos = await search_videos(client, UNSAVED_GOAL_ID, "chess openings", Language.ENGLISH)
        assert videos, "the search returned no videos"
        link = videos[0].link
        assert WATCH.match(link), link

        picture = await youtube_picture(client, link)

    assert picture, f"the validator rejected {link}, which the search just returned"
