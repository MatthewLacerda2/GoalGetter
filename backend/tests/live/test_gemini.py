"""Every Gemini use case, called for real once (#176). SPENDS QUOTA.

Gemini's words change on every call, so nothing here reads them. What is
asserted is what the code depends on: the answer parses into the schema the
caller receives, and a batch of N texts embeds into N vectors.

The inputs are `make gemini`'s own samples (`backend/tools/gemini_cli.py`):
one list of use cases, already type-checked against each function's signature
by the default suite, so a use case added there is called here without anyone
remembering to.
"""

import inspect

import numpy as np
import pytest

from backend.tools.gemini_cli import USE_CASES
from backend.utils.envs import NUM_DIMENSIONS
from backend.utils.gemini.gemini_configs import get_gemini_embeddings_batch

pytestmark = [pytest.mark.live, pytest.mark.usefixtures("gemini_key")]

# The resource search is more than a schema: what matters is whether its links
# exist, which test_resources.py asks.
SCHEMA_CASES = [case for case in USE_CASES if case.name != "resource-search"]


@pytest.mark.parametrize("case", SCHEMA_CASES, ids=lambda case: case.name)
def test_the_answer_parses_into_the_schema(case):
    returns = inspect.signature(case.call).return_annotation

    result = case.call(*case.build(list(case.sample)))

    assert isinstance(result, returns), f"{case.name} answered {type(result).__name__}"


def test_n_texts_embed_into_n_vectors():
    """#163: google-genai once read a list of texts as one content and answered
    one averaged vector for all of them. Two texts is the smallest batch."""
    texts = ["a knight fork", "a pawn endgame"]

    vectors = get_gemini_embeddings_batch(texts)

    assert len(vectors) == len(texts), f"asked for {len(texts)}, got {len(vectors)}"
    assert all(vector.shape == (NUM_DIMENSIONS,) for vector in vectors)
    assert not np.allclose(vectors[0], vectors[1])
