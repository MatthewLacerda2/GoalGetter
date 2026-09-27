import logging

from fastapi import HTTPException
from google.genai.errors import APIError

from backend.services.gemini.client.gemini_call import GeminiNoAnswer
from backend.services.gemini.client.gemini_retry import (
    BACKGROUND_BUDGET,
    REQUEST_BUDGET,
    RETRYABLE_EXCEPTIONS,
    using_budget,
)

logger = logging.getLogger(__name__)

# Gemini's statuses that are about OUR key, not the student's session. Passed
# through, they would reach the app as a 401/403 - which it reads as "you are
# signed out" - so they become a 502 like any other upstream fault.
_OUR_CREDENTIALS = frozenset({401, 403})


async def run_gemini(use_case, *args):
    """Run a Gemini use case for a request a user is waiting on, and surface
    what went wrong upstream to the client.

    Every call inside it retries on the short budget
    (backend/services/gemini/client/gemini_retry.py), so a single blip does not
    become a failed screen, and gives up rather than holding the request open.

    What reaches the client instead of a bare 500 and a stack trace:

    * a Gemini API error (depleted credits, quota, a bad request, a 5xx) keeps
      Gemini's own status code and message - except 401/403, which are about
      our key and would read as the student being signed out: those are 502;
    * an answer with nothing usable in it (`GeminiNoAnswer`) is a 502;
    * a call past its deadline is a 504, and so is a network failure, which has
      no status code of its own: the call never reached Gemini.

    Every other exception propagates, so genuine bugs stay visible as 500s.
    """
    try:
        with using_budget(REQUEST_BUDGET):
            return await use_case(*args)
    except GeminiNoAnswer as err:
        logger.warning("Gemini gave no answer: %s", err)
        raise HTTPException(status_code=502, detail="Gemini gave no usable answer") from err
    except APIError as err:
        logger.warning("Gemini API error %s: %s", err.code, err.message)
        status = 502 if not err.code or err.code in _OUR_CREDENTIALS else err.code
        raise HTTPException(status_code=status, detail=err.message) from err
    except TimeoutError as err:
        logger.warning("Gemini did not answer in time")
        raise HTTPException(status_code=504, detail="Gemini did not answer in time") from err
    except RETRYABLE_EXCEPTIONS as err:
        logger.warning("Gemini unreachable: %s", type(err).__name__)
        raise HTTPException(status_code=504, detail="Gemini is unreachable") from err


async def run_gemini_background(use_case, *args):
    """Run a Gemini use case for work nobody is waiting on.

    Same policy, a longer budget: a background job may back off for seconds
    where a request may not. The error is raised unchanged - the caller in
    backend/services/jobs/ logs it, and the nightly run is what fills the gap.
    """
    with using_budget(BACKGROUND_BUDGET):
        return await use_case(*args)
