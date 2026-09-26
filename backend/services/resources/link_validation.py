"""Liveness checks for the study resources the search found.

Pages come from Google's grounding sources as redirects
(`vertexaisearch.cloud.google.com/grounding-api-redirect/...`): the check
follows each one and stores the page it lands on, never the redirect (#175).
Videos come from the YouTube Data API's search; the check confirms each is
public and fills in its picture. Nothing here raises: a resource that fails its
check is quietly dropped, because no user is waiting on the answer.
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

# "A page that exists is good enough" (the user, #175): only these say it does
# not. A 403 is a bot wall in front of a page Google indexed, so it is kept.
GONE = (404, 410)
# Google's redirect host: a link still pointing here was never resolved.
REDIRECT_HOST = "vertexaisearch.cloud.google.com"

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


async def resolve_page(client: httpx.AsyncClient, url: str):
    """Follow `url` to the page it lands on. The response, or None when there
    is no page: the request failed, the page is gone (404/410), or the redirect
    never left Google's host."""
    try:
        response = await client.get(
            url, timeout=REQUEST_TIMEOUT, follow_redirects=True, headers=_BROWSER_UA
        )
    except httpx.HTTPError as exc:
        logger.info("Dropping %s: request failed (%s)", url, exc)
        return None
    if response.status_code in GONE:
        logger.info("Dropping %s: HTTP %s", response.url, response.status_code)
        return None
    if response.url.host == REDIRECT_HOST:
        logger.info("Dropping %s: the redirect did not resolve", url)
        return None
    return response


def is_pdf(response) -> bool:
    """The content type is the trustworthy signal; a `.pdf` path is accepted as
    a fallback because some hosts serve PDFs as octet-stream, and a bot wall
    answers HTML in front of one."""
    content_type = response.headers.get("content-type", "").lower()
    if "application/pdf" in content_type or response.url.path.lower().endswith(".pdf"):
        return True
    logger.info("Dropping %s: not a PDF (content-type %r)", response.url, content_type)
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
    """Decide one resource's fate: a page's link becomes where it landed, a
    video gets its picture."""
    if resource.resource_type == StudyResourceType.youtube:
        picture = await youtube_picture(client, resource.link)
        if picture is None:
            return False
        resource.image_url = picture
        return True
    response = await resolve_page(client, resource.link)
    if response is None:
        return False
    if resource.resource_type == StudyResourceType.pdf and not is_pdf(response):
        return False
    resource.link = str(response.url)
    return True


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
    for resource, verdict in zip(resources, verdicts, strict=True):
        if isinstance(verdict, BaseException):
            logger.warning("Dropping %s: check errored (%s)", resource.link, verdict)
        elif verdict:
            kept.append(resource)

    logger.info("Resource validation kept %d of %d", len(kept), len(resources))
    return kept
