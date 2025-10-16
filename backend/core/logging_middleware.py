from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response
from starlette.requests import Request
from datetime import datetime
import logging
import json
import time

logger = logging.getLogger(__name__)

class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        response = await call_next(request)
        process_time = time.time() - start_time

        log_data = {
            "method": request.method,
            "url": str(request.url),
            "headers": dict(request.headers),
            "query_params": dict(request.query_params),
            "client_ip": request.client.host,
            "status_code": response.status_code,
            "process_time_ms": round(process_time * 1000, 2),
            "datetime": datetime.now()
        }

        if response.status_code >= 400:
            
            response_body = [chunk async for chunk in response.body_iterator]
            
            response = Response(
                content=b''.join(response_body),
                status_code=response.status_code,
                headers=dict(response.headers),
                media_type=response.media_type
            )
            try:
                log_data["response_body"] = json.loads(response_body[0].decode())
            except Exception as e:
                log_data["response_body"] = response_body[0].decode()
        
        return response