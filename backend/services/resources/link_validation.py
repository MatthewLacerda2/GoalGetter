"""Liveness checks for the study resources Gemini recommends.

Gemini returns plausible-looking URLs that may be dead, of the wrong type, or
simply invented. Nothing here raises: a resource that fails its check is quietly
dropped, because no user is waiting on the answer (this runs in the background
job kicked off after goal creation).
"""
import asyncio
import logging
import re

import httpx

from backend.models.resource import Resource, StudyResourceType
from backend.utils.envs import YOUTUBE_API_KEY

logger = logging.getLogger(__name__)

REQUEST_TIMEOUT = 10.0
YOUTUBE_API = "https://www.googleapis.com/youtube/v3"

# Some hosts refuse an obviously robotic client, which would cost us a good link.
_BROWSER_UA = {"User-Agent": "Mozilla/5.0 (compatible; GoalGetter/1.0)"}

_VIDEO_ID = re.compile(
    r"(?:youtube\.com/(?:watch\?(?:.*&)?v=|shorts/|embed/)|youtu\.be/)([A-Za-z0-9_-]{11})"
)
_CHANNEL_ID = re.compile(r"youtube\.com/channel/(UC[A-Za-z0-9_-]{22})")
_HANDLE = re.compile(r"youtube\.com/@([A-Za-z0-9._-]+)")


async def _fetch(client: httpx.AsyncClient, url: str, params: dict | None = None):
    """GET that returns None instead of raising, and None on any 4xx/5xx."""
    try:
        response = await client.get(
            url,
            params=params,
            timeout=REQUEST_TIMEOUT,
            follow_redirects=True,
            headers=_BROWSER_UA,
        )
    except httpx.HTTPError as exc:
        logger.info("Dropping %s: request failed (%s)", url, exc)
        return None
    if response.status_code >= 400:
        logger.info("Dropping %s: HTTP %s", url, response.status_code)
        return None
    return response


async def is_live_webpage(client: httpx.AsyncClient, url: str) -> bool:
    """True when the page answers at all."""
    return await _fetch(client, url) is not None


async def is_live_pdf(client: httpx.AsyncClient, url: str) -> bool:
    """True when the link is reachable AND is actually a PDF.

    The content type is the trustworthy signal; a `.pdf` path is accepted as a
    fallback because some hosts serve PDFs as octet-stream.
    """
    response = await _fetch(client, url)
    if response is None:
        return False
    content_type = response.headers.get("content-type", "").lower()
    if "application/pdf" in content_type:
        return True
    if url.lower().split("?")[0].endswith(".pdf"):
        return True
    logger.info("Dropping %s: not a PDF (content-type %r)", url, content_type)
    return False


def _youtube_lookup(url: str) -> tuple[str, dict] | None:
    """Map a YouTube URL onto the Data API call that proves it exists."""
    video = _VIDEO_ID.search(url)
    if video:
        return "videos", {"part": "snippet,status", "id": video.group(1)}
    channel = _CHANNEL_ID.search(url)
    if channel:
        return "channels", {"part": "snippet", "id": channel.group(1)}
    handle = _HANDLE.search(url)
    if handle:
        return "channels", {"part": "snippet", "forHandle": handle.group(1)}
    return None


def _picture_from(item: dict) -> str | None:
    """The channel avatar, or the video thumbnail. Absent = we drop the resource."""
    thumbnails = item.get("snippet", {}).get("thumbnails", {}) or {}
    for size in ("high", "medium", "default"):
        url = (thumbnails.get(size) or {}).get("url")
        if url:
            return url
    return None


async def youtube_picture(client: httpx.AsyncClient, url: str) -> str | None:
    """Confirm the channel/video is real and public; return its picture URL."""
    lookup = _youtube_lookup(url)
    if lookup is None:
        logger.info("Dropping %s: not a recognisable YouTube link", url)
        return None
    if not YOUTUBE_API_KEY:
        logger.warning("YOUTUBE_API_KEY unset - cannot verify %s, dropping it", url)
        return None

    endpoint, params = lookup
    response = await _fetch(
        client, f"{YOUTUBE_API}/{endpoint}", params={**params, "key": YOUTUBE_API_KEY}
    )
    if response is None:
        return None

    items = response.json().get("items") or []
    if not items:
        logger.info("Dropping %s: YouTube returned no such item", url)
        return None

    item = items[0]
    privacy = item.get("status", {}).get("privacyStatus")
    if privacy and privacy != "public":
        logger.info("Dropping %s: video is %s", url, privacy)
        return None
    return _picture_from(item)


async def _keep(client: httpx.AsyncClient, resource: Resource) -> bool:
    """Decide one resource's fate, filling in image_url for YouTube."""
    if resource.resource_type == StudyResourceType.youtube:
        picture = await youtube_picture(client, resource.link)
        if picture is None:
            return False
        resource.image_url = picture
        return True
    if resource.resource_type == StudyResourceType.pdf:
        return await is_live_pdf(client, resource.link)
    return await is_live_webpage(client, resource.link)


async def validate_resources(
    resources: list[Resource], client: httpx.AsyncClient | None = None
) -> list[Resource]:
    """Return only the resources whose links we could confirm.

    Checks run concurrently; a checker that blows up costs that one resource, not
    the batch. Pass `client` to reuse a connection pool (and in tests).
    """
    if not resources:
        return []

    owned = client is None
    client = client or httpx.AsyncClient()
    try:
        verdicts = await asyncio.gather(
            *(_keep(client, resource) for resource in resources),
            return_exceptions=True,
        )
    finally:
        if owned:
            await client.aclose()

    kept = []
    for resource, verdict in zip(resources, verdicts):
        if isinstance(verdict, BaseException):
            logger.warning("Dropping %s: check errored (%s)", resource.link, verdict)
        elif verdict:
            kept.append(resource)

    logger.info("Resource validation kept %d of %d", len(kept), len(resources))
    return kept
