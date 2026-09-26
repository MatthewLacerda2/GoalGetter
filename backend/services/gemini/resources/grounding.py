"""The pages a grounded search actually found, read from its metadata (#175).

A response to a call with the Google Search tool carries two things: the text
the model wrote, and `grounding_metadata` - what Google returned. The links in
the text are the model's and were invented (the first real student's nine
resources were all dead); the links in `grounding_chunks` are Google's. This
module reads only the second.

The real shape (captured 2026-09-26, `tests/fixtures/responses/`):

* `grounding_chunks[i].web.uri` is a `vertexaisearch.cloud.google.com` redirect,
  not the page. `link_validation` follows it and stores where it lands.
* `grounding_chunks[i].web.title` is only the domain ("chess.com").
* `grounding_supports[j]` ties a span of the model's text to the chunks it came
  from - the only per-source description the response holds, so it is what the
  describing call is shown.
"""

import re
from dataclasses import dataclass

# Videos come from the YouTube Data API's search, where an ID exists by
# construction; a YouTube page surfacing through web search is left to it.
VIDEO_SITES = ("youtube.com", "youtu.be")

# What the describing call reads per source: enough to name the page, and a cap
# so a source cited all over the text does not bill for all of it.
SNIPPET_CHARS = 300

# The model's text is shown without the links it wrote - an invented URL in the
# describing prompt is one it could hand back as a name, and bills as tokens.
_WRITTEN_LINK = re.compile(r"\[?\(?https?://[^\s)\]]+[)\]]*")


@dataclass(frozen=True)
class WebSource:
    uri: str
    site: str
    said: str


def web_sources(response) -> list[WebSource]:
    """Each distinct web page the search found, in the order Google gave them,
    with what the model's text said about it."""
    candidates = response.candidates or []
    metadata = candidates[0].grounding_metadata if candidates else None
    if metadata is None:
        return []

    said: dict[int, list[str]] = {}
    for support in metadata.grounding_supports or []:
        text = support.segment.text or "" if support.segment else ""
        text = " ".join(_WRITTEN_LINK.sub("", text).split())
        for index in support.grounding_chunk_indices or []:
            if text and text not in said.setdefault(index, []):
                said[index].append(text)

    sources, seen = [], set()
    for index, chunk in enumerate(metadata.grounding_chunks or []):
        web = chunk.web
        if web is None or not web.uri or web.uri in seen:
            continue
        site = (web.title or "").lower()
        if any(site == v or site.endswith("." + v) for v in VIDEO_SITES):
            continue
        seen.add(web.uri)
        sources.append(WebSource(web.uri, site, _snippet(said.get(index, []))))
    return sources


def _snippet(texts: list[str]) -> str:
    """Supports nest - one span, then the same span grown by a line - so a
    text another one already contains is left out."""
    widest = [t for t in texts if not any(t != other and t in other for other in texts)]
    return " ".join(widest)[:SNIPPET_CHARS]


def numbered(sources: list[WebSource]) -> str:
    """The sources as the describing prompt lists them - numbered, no URLs, so
    there is no link in the prompt for the model to copy or alter."""
    return "\n".join(f"[{n}] {s.site}: {s.said or '(no text)'}" for n, s in enumerate(sources))
