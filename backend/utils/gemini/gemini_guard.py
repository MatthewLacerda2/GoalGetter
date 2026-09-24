import logging
from fastapi import HTTPException
from fastapi.concurrency import run_in_threadpool
from google.genai.errors import APIError

logger = logging.getLogger(__name__)

async def run_gemini(func, *args):
    """Run a blocking Gemini SDK call off the event loop and surface upstream API
    errors to the client.

    Gemini failures (depleted credits, quota, bad request, 5xx) are re-raised as
    an HTTPException carrying Gemini's own status code and message, instead of
    leaking an unhandled 500 + stack trace. Non-API errors are left to propagate
    so genuine bugs stay visible as 500s.
    """
    try:
        return await run_in_threadpool(func, *args)
    except APIError as err:
        logger.warning("Gemini API error %s: %s", err.code, err.message)
        raise HTTPException(status_code=err.code or 502, detail=err.message)
