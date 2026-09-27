"""The one way a use case asks Gemini for something.

Every use case under `services/gemini/<use-case>/` keeps its folder - the
schema, the prompt, the function the rest of the app calls - and that function
reaches Gemini through here and nowhere else. What every one of them needs
lives here once:

* the client, reused (`gemini_configs.get_client`);
* the deadline and the retries, per billed call (`gemini_retry.call_with_retry`),
  so a use case that makes two calls retries each on its own;
* an answer with nothing in it - a safety block, an empty candidate, text that
  is not the schema - which becomes `GeminiNoAnswer` rather than a
  `ValidationError` that would reach the student as a bare 500.

`generate` is the typed call: it takes the schema and answers an instance of
it. `grounded_search` is the one call whose answer is not a schema - the
resource search keeps the grounding metadata and throws the text away.
"""

import logging

from google.genai.types import (
    ContentListUnion,
    ContentListUnionDict,
    GenerateContentConfig,
    GenerateContentResponse,
    GoogleSearch,
    Tool,
)
from pydantic import BaseModel, ValidationError

from backend.services.gemini.client import gemini_configs
from backend.services.gemini.client.gemini_retry import call_with_retry

logger = logging.getLogger(__name__)

type Contents = ContentListUnion | ContentListUnionDict

# What `grounded_search` answers, named here so the callers that read it need
# not import google.genai themselves (an import contract keeps it inside client/).
GroundedResponse = GenerateContentResponse

# How much of an answer that failed to parse reaches the log: enough to see
# what came back instead, not a whole batch of exercises per line.
LOGGED_CHARS = 300


class GeminiNoAnswer(Exception):
    """Gemini answered - and billed - but said nothing the caller can use.

    Not a bug of ours and not a transport failure, so it is never retried: a
    blocked prompt is blocked again. A request turns it into `gemini_no_answer`, a
    502 (see `gemini_guard.run_gemini`).
    """

    def __init__(self, model: str, reason: str):
        super().__init__(f"{model} gave no usable answer: {reason}")
        self.model = model
        self.reason = reason


async def generate[T: BaseModel](model: str, contents: Contents, schema: type[T]) -> T:
    """Ask `model` for an answer shaped like `schema`, and return it parsed."""
    config = gemini_configs.get_gemini_config(schema)
    response = await _send(model, contents, config, schema.__name__)
    return _parsed(response, schema, model)


async def grounded_search(model: str, contents: Contents) -> GenerateContentResponse:
    """A plain-text call with the Google Search tool. The caller reads the
    response's grounding metadata, not its text, so the whole response is
    returned and nothing here parses it."""
    config = gemini_configs.get_gemini_config_plain_text(tools=[Tool(google_search=GoogleSearch())])
    return await _send(model, contents, config, "grounded search")


async def _send(
    model: str, contents: Contents, config: GenerateContentConfig, name: str
) -> GenerateContentResponse:
    """One billed call: retried, under a deadline, on the shared client."""
    client = gemini_configs.get_client()
    return await call_with_retry(
        lambda: client.aio.models.generate_content(model=model, contents=contents, config=config),
        f"{model} {name}",
    )


def _parsed[T: BaseModel](response: GenerateContentResponse, schema: type[T], model: str) -> T:
    text = response.text
    if not text:
        raise GeminiNoAnswer(model, _why_empty(response))
    try:
        return schema.model_validate_json(text)
    except ValidationError as error:
        logger.warning("%s answered outside %s: %s", model, schema.__name__, text[:LOGGED_CHARS])
        raise GeminiNoAnswer(model, f"the answer is not a {schema.__name__}") from error


def _why_empty(response: GenerateContentResponse) -> str:
    """What the response says about its own silence: the prompt's block reason,
    else the first candidate's finish reason."""
    feedback = getattr(response, "prompt_feedback", None)
    blocked = getattr(feedback, "block_reason", None)
    if blocked:
        return f"prompt blocked ({blocked})"
    candidates = getattr(response, "candidates", None) or []
    finish = getattr(candidates[0], "finish_reason", None) if candidates else None
    return f"empty answer (finish reason {finish})" if finish else "empty answer"
