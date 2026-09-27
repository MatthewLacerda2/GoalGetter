"""The parts of the YouTube Data API's answers this code reads (#209).

Typed so a misspelt key is a type error rather than a resource silently dropped.
`total=False` throughout: every field is read with `.get`, because the API
leaves out what a video or channel does not have. They describe the JSON; they
do not validate it - an answer is read as it comes, the way it always was.
"""

from typing import TypedDict


class Thumbnail(TypedDict, total=False):
    url: str


class Snippet(TypedDict, total=False):
    title: str
    description: str
    thumbnails: dict[str, Thumbnail]


class Status(TypedDict, total=False):
    privacyStatus: str


class Item(TypedDict, total=False):
    """One entry of `videos.list` or `channels.list`: what proves it exists."""

    snippet: Snippet
    status: Status


class SearchId(TypedDict, total=False):
    videoId: str


class SearchResult(TypedDict, total=False):
    """One entry of `search.list`, whose `id` is an object, not a string."""

    id: SearchId
    snippet: Snippet
