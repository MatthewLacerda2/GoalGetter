"""The resource search, end to end against the real APIs (#176). SPENDS QUOTA.

#175: Gemini once recommended nine links and all nine were invented, and the
first real student got no resources at all. The contract is the one the student
sees - **at least one recommended resource survives link validation** - so it
holds whatever the search does inside, and whoever rewrites the search only has
to keep it true.
"""

import pytest

from backend.services.gemini.resources.search_resources import search_resources
from backend.services.resources.link_validation import validate_resources
from backend.tools.gemini_cli import UNSAVED_GOAL_ID, USE_CASES

pytestmark = [pytest.mark.live, pytest.mark.usefixtures("gemini_key", "youtube_key")]

SAMPLE = next(case for case in USE_CASES if case.name == "resource-search").sample


async def test_at_least_one_recommended_resource_survives_validation():
    recommended = search_resources(UNSAVED_GOAL_ID, *SAMPLE)

    kept = await validate_resources(recommended)

    links = "\n".join(resource.link for resource in recommended)
    assert kept, f"0 of {len(recommended)} survived link validation:\n{links}"
