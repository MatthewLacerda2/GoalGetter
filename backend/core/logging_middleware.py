from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response
from starlette.requests import Request
from datetime import datetime
import logging
import time

logger = logging.getLogger(__name__)

class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        response = await call_next(request)

        if response.status_code >= 400:
            
            response_body = [chunk async for chunk in response.body_iterator]
            
            response = Response(
                content=b''.join(response_body),
                status_code=response.status_code,
                headers=dict(response.headers),
                media_type=response.media_type
            )
        
        # Simple, clean logging with just the essentials
        logger.info(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - {request.client.host} - {request.method} {request.url.path} - {response.status_code}")
        
        return response