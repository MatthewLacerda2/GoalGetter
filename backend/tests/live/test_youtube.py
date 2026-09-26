"""The YouTube Data API, called for real once (#176). SPENDS QUOTA.

A search is the tool that finds videos (CLAUDE.md: Gemini never supplies a
link from memory), and the link validator is what proves a video exists. The
contract between them: an ID a search returns is one the validator accepts.
"""

import re

import httpx
import pytest

from backend.services.resources.link_validation import YOUTUBE_API, youtube_picture
from backend.utils.envs import YOUTUBE_API_KEY

pytestmark = [pytest.mark.live, pytest.mark.usefixtures("youtube_key")]

VIDEO_ID = re.compile(r"^[A-Za-z0-9_-]{11}$")


async def test_a_searched_video_id_exists():
    async with httpx.AsyncClient() as client:
        search = await client.get(
            f"{YOUTUBE_API}/search",
            params={
                "part": "id",
                "type": "video",
                "maxResults": 1,
                "q": "chess openings",
                "key": YOUTUBE_API_KEY,
            },
        )
        assert search.status_code == 200, search.text
        video_id = search.json()["items"][0]["id"]["videoId"]
        assert VIDEO_ID.match(video_id), video_id

        picture = await youtube_picture(client, f"https://www.youtube.com/watch?v={video_id}")

    assert picture, f"the validator rejected {video_id}, which the search just returned"
