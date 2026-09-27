import logging
from collections.abc import Awaitable, Callable

from google.genai.errors import APIError

from backend.core.errors.api_error import ApiError
from backend.core.errors.codes import ErrorCode
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
# signed out" - so they have a code, and a 5xx, of their own (#214).
_OUR_CREDENTIALS = frozenset({401, 403})
# Gemini's 429: our quota or prepaid credits ran out - not the student's pace,
# which is what a 429 of ours means to the app.
_OUR_QUOTA = 429


def _api_error_code(status: int | None) -> ErrorCode:
    if status in _OUR_CREDENTIALS:
        return ErrorCode.GEMINI_KEY_REJECTED
    if status == _OUR_QUOTA:
        return ErrorCode.GEMINI_QUOTA_EXHAUSTED
    return ErrorCode.GEMINI_FAILED


async def run_gemini[**P, R](
    use_case: Callable[P, Awaitable[R]], *args: P.args, **kwargs: P.kwargs
) -> R:
    """Run a Gemini use case for a request a user is waiting on, and surface
    what went wrong upstream to the client.

    It answers what `use_case` answers, and the type checker holds `args` and
    `kwargs` to `use_case`'s own signature: an argument of the wrong type,
    or one too many, fails `make back-types` rather than a request.

    Every call inside it retries on the short budget
    (backend/services/gemini/client/gemini_retry.py), so a single blip does not
    become a failed screen, and gives up rather than holding the request open.

    What reaches the client instead of a bare 500 and a stack trace is an
    `ApiError` with a Gemini code of its own (backend/core/errors/codes.py),
    always a 5xx - whatever Gemini answered is our upstream's failure, never
    the student's request or session:

    * Gemini's 401/403 (our key) is `gemini_key_rejected`, a 502 - passed
      through, it would read as the student being signed out;
    * its 429 (our quota or credits) is `gemini_quota_exhausted`, a 503;
    * any other API error (a bad request, a 5xx) is `gemini_failed`, a 502;
    * an answer with nothing usable in it (`GeminiNoAnswer`) is a 502;
    * a call past its deadline is a 504, and so is a network failure, which has
      no status code of its own: the call never reached Gemini.

    Gemini's own status and message go to the log, not to the client.

    Every other exception propagates, so genuine bugs stay visible as 500s.
    """
    try:
        with using_budget(REQUEST_BUDGET):
            return await use_case(*args, **kwargs)
    except GeminiNoAnswer as err:
        logger.warning("Gemini gave no answer: %s", err)
        raise ApiError(ErrorCode.GEMINI_NO_ANSWER) from err
    except APIError as err:
        logger.warning("Gemini API error %s: %s", err.code, err.message)
        raise ApiError(_api_error_code(err.code)) from err
    except TimeoutError as err:
        logger.warning("Gemini did not answer in time")
        raise ApiError(ErrorCode.GEMINI_TIMED_OUT) from err
    except RETRYABLE_EXCEPTIONS as err:
        logger.warning("Gemini unreachable: %s", type(err).__name__)
        raise ApiError(ErrorCode.GEMINI_UNREACHABLE) from err


async def run_gemini_background[**P, R](
    use_case: Callable[P, Awaitable[R]], *args: P.args, **kwargs: P.kwargs
) -> R:
    """Run a Gemini use case for work nobody is waiting on.

    Same policy, a longer budget: a background job may back off for seconds
    where a request may not. The error is raised unchanged - the caller in
    backend/services/jobs/ logs it, and the nightly run is what fills the gap.
    """
    with using_budget(BACKGROUND_BUDGET):
        return await use_case(*args, **kwargs)
