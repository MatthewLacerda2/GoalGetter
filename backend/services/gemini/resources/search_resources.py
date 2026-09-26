"""Web pages and PDFs for one goal, found by Google and described by Gemini (#175).

Two calls. The first has the Google Search tool and does the finding; its text
is thrown away and only its grounding sources are kept (`grounding.py`). The
second, without tools, is shown those sources by number and says which are worth
the student's time and what each teaches - and answers numbers, never links. So
every link this returns is one Google found; none is one Gemini remembers.

Videos are not found here: the second call writes a search query, and
`services/resources/youtube_search.py` asks the YouTube Data API for them.
"""

import logging
from dataclasses import dataclass

from google.genai import types

from backend.core.language import Language
from backend.models.resource import Resource, StudyResourceType
from backend.services.gemini.resources.grounding import WebSource, numbered, web_sources
from backend.services.gemini.resources.prompt import describe_prompt, search_prompt
from backend.services.gemini.resources.schema import DescribedSource, DescribedSources
from backend.utils.envs import GEMINI_FAST_MODEL
from backend.utils.gemini.gemini_configs import (
    get_client,
    get_gemini_config,
    get_gemini_config_plain_text,
)

logger = logging.getLogger(__name__)

# Three of each: with three videos, the nine resources a goal is given.
PER_TYPE = 3


@dataclass
class ResourceSearch:
    """What the search found: pages whose `link` is still Google's redirect
    (`validate_resources` resolves it), and the query to find videos with."""

    pages: list[Resource]
    video_query: str


def search_resources(
    goal_id: str,
    goal_name: str,
    goal_description: str,
    student_context: str | None = None,
    existing_links: list[str] | None = None,
    language: Language = Language.ENGLISH,
) -> ResourceSearch:
    """`student_context` is the app's reading of the learner - the chain never
    calls this without one ("no resources without memory", the user); it stays
    optional so `make gemini resource-search` runs on a goal alone.
    `existing_links` are the goal's links, so a second run looks for others;
    the caller still dedupes, because asking is not obeying.

    No embedding is bought here: `description_embedding` stays null until the
    midnight batch fills it (#96), so a link that fails validation costs nothing.
    """
    client = get_client()
    context = student_context or "nothing yet"
    tongue = language.english_name

    found = client.models.generate_content(
        model=GEMINI_FAST_MODEL,
        contents=search_prompt(goal_name, goal_description, context, existing_links or [], tongue),
        config=get_gemini_config_plain_text(tools=[types.Tool(google_search=types.GoogleSearch())]),
    )
    sources = web_sources(found)
    logger.info("The grounded search found %d web sources", len(sources))

    described = DescribedSources.model_validate_json(
        client.models.generate_content(
            model=GEMINI_FAST_MODEL,
            contents=describe_prompt(goal_name, context, numbered(sources), tongue),
            config=get_gemini_config(DescribedSources.model_json_schema()),
        ).text
    )
    return ResourceSearch(pages_from(goal_id, sources, described.resources), described.video_query)


def pages_from(
    goal_id: str, sources: list[WebSource], described: list[DescribedSource]
) -> list[Resource]:
    """A row per described source, its link the source's own. A number that
    points at no source, or at one already taken, is dropped, and so is a
    fourth page of one type."""
    pages, used, per_type = [], set(), dict.fromkeys(("webpage", "pdf"), 0)
    for item in described:
        if not 0 <= item.source < len(sources) or item.source in used:
            logger.info("Dropping source %d: no such source, or described twice", item.source)
            continue
        if per_type[item.resource_type] >= PER_TYPE:
            continue
        used.add(item.source)
        per_type[item.resource_type] += 1
        pages.append(
            Resource(
                goal_id=goal_id,
                resource_type=StudyResourceType(item.resource_type),
                name=item.name,
                description=item.description,
                language=item.language.lower()[:2],
                link=sources[item.source].uri,
            )
        )
    return pages
