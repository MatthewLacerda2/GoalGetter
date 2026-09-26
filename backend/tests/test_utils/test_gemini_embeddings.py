"""What the embedding batch asks Gemini for, read off the SDK's own request.

Every other test mocks the whole Gemini call, so a change inside google-genai
cannot turn one of them red. This one lets the real SDK build the request and
stops it at the transport - nothing leaves the process - because the batch's
contract (one vector per text) is decided by that request's shape (#163).
"""

import pytest
from google.genai import Client

from backend.utils.envs import EMBEDDING_MODEL, NUM_DIMENSIONS
from backend.utils.gemini import gemini_configs


class Stop(Exception):
    """Raised where the SDK would go to the network."""


def test_the_batch_asks_for_one_embedding_per_text(monkeypatch):
    sent = []

    def transport(http_method, path, request_dict, http_options=None):
        sent.append((path, request_dict))
        raise Stop

    client = Client(api_key="offline")
    monkeypatch.setattr(client._api_client, "request", transport)
    monkeypatch.setattr(gemini_configs, "get_client", lambda: client)

    with pytest.raises(Stop):
        gemini_configs.get_gemini_embeddings_batch(["alpha", "beta", "gamma"])

    path, body = sent[0]
    assert path == f"models/{EMBEDDING_MODEL}:batchEmbedContents"
    texts = [[part["text"] for part in r["content"]["parts"]] for r in body["requests"]]
    assert texts == [["alpha"], ["beta"], ["gamma"]]
    assert {r["outputDimensionality"] for r in body["requests"]} == {NUM_DIMENSIONS}
