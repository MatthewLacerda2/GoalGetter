from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response
from starlette.requests import Request
import logging

logger = logging.getLogger(__name__)

class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)

        if response.status_code >= 400:
            try:
                error_msg = b''.join(response_body).decode()
            except Exception:
                error_msg = "[Binary or Undecodable Error Body]"
            logger.error(f"Error Body: {error_msg}")
            
            response_body = [chunk async for chunk in response.body_iterator]
            response = Response(
                content=b''.join(response_body),
                status_code=response.status_code,
                headers=dict(response.headers),
                media_type=response.media_type
            )
        
        real_ip = request.headers.get("cf-connecting-ip") or request.client.host
        logger.info(f"IP: {real_ip} | {request.method} {request.url.path} | Status: {response.status_code}")
        
        return response