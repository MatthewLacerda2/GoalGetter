"""The pages the Gemini search found, as the rows the resources step stores.

The search returns content (`FoundPage`) and never builds a `Resource` itself:
the Gemini layer writes content, and what the database holds is decided outside
it (#211, the import contracts in backend/pyproject.toml). The videos need no
such step - `youtube_search.py` is not the Gemini layer and builds its rows.
"""

from backend.models.resource import Resource, StudyResourceType
from backend.services.gemini.resources.search_resources import FoundPage


def page_resources(goal_id: str, pages: list[FoundPage]) -> list[Resource]:
    """A `Resource` per page, for `goal_id`, its link still the redirect that
    `validate_resources` follows. No embedding: the midnight batch fills it (#96)."""
    return [
        Resource(
            goal_id=goal_id,
            resource_type=StudyResourceType(page.resource_type),
            name=page.name,
            description=page.description,
            language=page.language,
            link=page.link,
        )
        for page in pages
    ]
