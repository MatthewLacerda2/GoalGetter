"""Every exception that reaches FastAPI answers an `ErrorResponse` (#214).

Four ways an error leaves the app, one handler each:

- an `HTTPException` — ours (`ApiError`, which names its code) or one FastAPI
  and Starlette raise on their own: an unknown route, a wrong method, a
  missing bearer token. Those are given the code their status means;
- a `RequestValidationError` — the body or the query did not parse;
- slowapi's `RateLimitExceeded`;
- anything else — a bug, or the database down: a 500 whose body names no
  cause. Starlette still re-raises it after answering, so the traceback is
  logged as before.
"""

import logging

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from slowapi.errors import RateLimitExceeded
from starlette.exceptions import HTTPException as StarletteHTTPException

from backend.core.errors.api_error import ApiError
from backend.core.errors.codes import ErrorCode
from backend.core.errors.response import ErrorResponse

logger = logging.getLogger(__name__)

# The statuses FastAPI and Starlette raise by themselves, with no ApiError.
_FRAMEWORK_CODES = {
    401: ErrorCode.NOT_SIGNED_IN,  # HTTPBearer: no Authorization header
    404: ErrorCode.ROUTE_NOT_FOUND,
    405: ErrorCode.METHOD_NOT_ALLOWED,
}


def error_response(
    code: ErrorCode, detail: str | None = None, headers: dict[str, str] | None = None
) -> JSONResponse:
    body = ErrorResponse(code=code, detail=detail or code.sentence)
    return JSONResponse(body.model_dump(mode="json"), status_code=code.status, headers=headers)


async def _http_error(_request: Request, exc: StarletteHTTPException) -> JSONResponse:
    if isinstance(exc, ApiError):
        return error_response(exc.code, exc.detail, exc.headers)
    code = _FRAMEWORK_CODES.get(exc.status_code)
    if code is None:
        # A raise that bypassed ApiError: a bug to fix by giving it a code.
        logger.error("HTTPException %s has no ErrorCode: %s", exc.status_code, exc.detail)
        code = ErrorCode.INTERNAL_ERROR
    return error_response(code, str(exc.detail), exc.headers)


async def _invalid_request(_request: Request, exc: RequestValidationError) -> JSONResponse:
    fields = "; ".join(
        f"{'.'.join(str(part) for part in error['loc'])}: {error['msg']}" for error in exc.errors()
    )
    return error_response(ErrorCode.INVALID_REQUEST, fields)


def _too_many_requests(_request: Request, exc: RateLimitExceeded) -> JSONResponse:
    # Synchronous on purpose: SlowAPIMiddleware calls it directly for the
    # default limit, and falls back to its own body for a coroutine.
    return error_response(ErrorCode.TOO_MANY_REQUESTS, f"Rate limit exceeded: {exc.detail}")


async def _internal_error(_request: Request, _exc: Exception) -> JSONResponse:
    return error_response(ErrorCode.INTERNAL_ERROR)


def install_error_handlers(app: FastAPI) -> None:
    app.add_exception_handler(StarletteHTTPException, _http_error)
    app.add_exception_handler(RequestValidationError, _invalid_request)
    # Registered by its own class: slowapi's middleware looks the handler up by
    # the exact type it raised, not by its HTTPException base.
    app.add_exception_handler(RateLimitExceeded, _too_many_requests)
    app.add_exception_handler(Exception, _internal_error)
