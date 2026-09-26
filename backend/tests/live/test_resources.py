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
from backend.tools.gemini_cli import USE_CASES

pytestmark = [pytest.mark.live, pytest.mark.usefixtures("gemini_key", "youtube_key")]

# `make gemini`'s own entry, so the arguments are the ones the default suite
# type-checks against the signature (the language among them, #173).
CASE = next(case for case in USE_CASES if case.name == "resource-search")


async def test_at_least_one_recommended_resource_survives_validation():
    recommended = search_resources(*CASE.build(list(CASE.sample)))

    kept = await validate_resources(recommended)

    links = "\n".join(resource.link for resource in recommended)
    assert kept, f"0 of {len(recommended)} survived link validation:\n{links}"
