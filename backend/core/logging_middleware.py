import logging

from starlette.middleware.base import (
    BaseHTTPMiddleware,
    RequestResponseEndpoint,
    _StreamingResponse,
)
from starlette.requests import Request
from starlette.responses import Response

logger = logging.getLogger(__name__)


class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        if request.url.path == "/api/v1/check":
            return await call_next(request)

        response = await call_next(request)

        # `call_next` always answers Starlette's streaming response, whose body
        # arrives as bytes; the checks name the types the code below reads.
        if response.status_code >= 400 and isinstance(response, _StreamingResponse):
            response_body = [
                chunk async for chunk in response.body_iterator if isinstance(chunk, bytes)
            ]
            try:
                error_msg = b"".join(response_body).decode()
            except UnicodeDecodeError:
                error_msg = "[Binary or Undecodable Error Body]"
            # A 4xx is the client's request refused - a missing goal, an expired
            # token - and routine; only a 5xx is a failure worth an ERROR.
            level = logging.ERROR if response.status_code >= 500 else logging.INFO
            logger.log(level, "Error Body: %s", error_msg)

            response = Response(
                content=b"".join(response_body),
                status_code=response.status_code,
                headers=dict(response.headers),
                media_type=response.media_type,
            )

        real_ip = request.headers.get("cf-connecting-ip") or (
            request.client.host if request.client else None
        )
        logger.info(
            "IP: %s | %s %s | Status: %s",
            real_ip,
            request.method,
            request.url.path,
            response.status_code,
        )

        return response
