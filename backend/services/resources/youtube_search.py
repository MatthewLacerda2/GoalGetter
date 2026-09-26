"""Videos for one goal, from the YouTube Data API's search (#175).

The API is the tool that finds videos, so it does: Gemini only writes the query
(it knows the student), and every ID stored is one YouTube returned. Before
this, video IDs were recalled by a language model, and invented.

The name and description are the video's own `snippet` - real data where a tool
has it, so no Gemini call describes a video (CLAUDE.md: Gemini is the tool of
last resort).

Quota: a `search.list` costs 100 units against a free 10,000 a day, so one
search per goal per run - three results from one query - caps the app at about
a hundred resource runs a day before validation's 1-unit lookups are counted.
"""

import html
import logging

import httpx

from backend.core.language import Language
from backend.models.resource import Resource, StudyResourceType
from backend.services.resources.link_validation import REQUEST_TIMEOUT, YOUTUBE_API
from backend.utils.envs import YOUTUBE_API_KEY

logger = logging.getLogger(__name__)

VIDEOS = 3
# A snippet's description is cut by YouTube near 160 characters and ends in
# "..."; the row keeps it whole below this cap.
DESCRIPTION_CHARS = 200


async def search_videos(
    client: httpx.AsyncClient, goal_id: str, query: str, language: Language
) -> list[Resource]:
    """Up to three videos for `query`, preferring the student's language.
    Nothing raises: a failed search is no videos tonight, not a failed chain."""
    if not YOUTUBE_API_KEY or not query.strip():
        logger.warning("No YouTube search: %s", "no key" if query.strip() else "no query")
        return []
    try:
        response = await client.get(
            f"{YOUTUBE_API}/search",
            params={
                "part": "snippet",
                "type": "video",
                "q": query,
                "maxResults": VIDEOS,
                "relevanceLanguage": language.value,
                "key": YOUTUBE_API_KEY,
            },
            timeout=REQUEST_TIMEOUT,
        )
    except httpx.HTTPError as exc:
        logger.warning("YouTube search failed: %s", exc)
        return []
    if response.status_code != 200:
        logger.warning("YouTube search answered HTTP %s", response.status_code)
        return []

    videos = []
    for item in response.json().get("items") or []:
        video_id = (item.get("id") or {}).get("videoId")
        snippet = item.get("snippet") or {}
        if not video_id or not snippet.get("title"):
            continue
        title = html.unescape(snippet["title"])
        about = html.unescape(snippet.get("description") or "") or title
        videos.append(
            Resource(
                goal_id=goal_id,
                resource_type=StudyResourceType.youtube,
                name=title,
                description=about[:DESCRIPTION_CHARS],
                language=language.value,
                link=f"https://www.youtube.com/watch?v={video_id}",
            )
        )
    return videos
