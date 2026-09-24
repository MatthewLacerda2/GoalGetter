import logging

from fastapi import HTTPException
from google.genai.errors import APIError

from backend.utils.gemini.gemini_retry import (
    BACKGROUND_BUDGET,
    REQUEST_BUDGET,
    RETRYABLE_EXCEPTIONS,
    call_with_retry,
)

logger = logging.getLogger(__name__)


async def run_gemini(func, *args):
    """Run a blocking Gemini SDK call for a request a user is waiting on, and
    surface upstream API errors to the client.

    Retries what can recover on a short budget (backend/utils/gemini/gemini_retry.py)
    so a single blip does not become a failed screen, then gives up rather than
    holding the request open.

    Gemini failures (depleted credits, quota, bad request, 5xx) are re-raised as
    an HTTPException carrying Gemini's own status code and message, instead of
    leaking an unhandled 500 + stack trace. A network failure has no status code
    of its own, so it becomes a 504: the call never reached Gemini. Every other
    exception is left to propagate so genuine bugs stay visible as 500s.
    """
    try:
        return await call_with_retry(func, *args, budget=REQUEST_BUDGET)
    except APIError as err:
        logger.warning("Gemini API error %s: %s", err.code, err.message)
        raise HTTPException(status_code=err.code or 502, detail=err.message) from err
    except RETRYABLE_EXCEPTIONS as err:
        logger.warning("Gemini unreachable: %s", type(err).__name__)
        raise HTTPException(status_code=504, detail="Gemini is unreachable") from err


async def run_gemini_background(func, *args):
    """Run a blocking Gemini SDK call for work nobody is waiting on.

    Same policy, a longer budget: a background job may back off for seconds
    where a request may not. The error is raised unchanged - the caller in
    backend/services/jobs/ logs it, and the nightly run is what fills the gap.
    """
    return await call_with_retry(func, *args, budget=BACKGROUND_BUDGET)
