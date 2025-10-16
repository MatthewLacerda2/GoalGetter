from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response
from starlette.requests import Request
import logging

logger = logging.getLogger(__name__)

# In-memory set to store banned IPs (resets on server restart)
banned_ips = set()

class IPBanMiddleware(BaseHTTPMiddleware):
    """
    Middleware to ban IPs that attempt to access malicious routes:
    - Routes ending with '.rsp'
    - Routes starting with '/boaform'
    - Routes starting with '/admin'
    """
    
    def __init__(self, app, ban_duration_minutes: int = 60):
        super().__init__(app)
        self.ban_duration_minutes = ban_duration_minutes
    
    def is_malicious_route(self, path: str) -> bool:
        """Check if the route matches known malicious patterns"""
        path_lower = path.lower()
        
        if 'server.js' in path_lower:
            return True
        
        # Check for routes ending with .rsp
        if '.rsp' in path_lower:
            return True
            
        # Check for routes starting with /boaform
        if 'boaform' in path_lower:
            return True
            
        # Check for routes starting with /admin
        if 'admin' in path_lower:
            return True
            
        return False
    
    async def dispatch(self, request: Request, call_next):
        client_ip = request.client.host
        path = request.url.path
        
        # Check if IP is already banned
        if client_ip in banned_ips:
            logger.warning(f"Banned IP {client_ip} attempted to access {path}")
            return Response(
                content="Access denied",
                status_code=403,
                media_type="text/plain"
            )
        
        # Check if this is a malicious route
        if self.is_malicious_route(path):
            # Ban the IP immediately
            banned_ips.add(client_ip)
            logger.warning(f"BANNED IP {client_ip} for attempting to access malicious route: {path}")
            
            return Response(
                content="Access denied",
                status_code=403,
                media_type="text/plain"
            )
        
        # If not malicious, proceed normally
        response = await call_next(request)
        return response
    
    @staticmethod
    def get_banned_count() -> int:
        """Get the number of currently banned IPs"""
        return len(banned_ips)
    
    @staticmethod
    def get_banned_ips() -> set:
        """Get the set of currently banned IPs"""
        return banned_ips.copy()
    
    @staticmethod
    def ban_ip(ip: str) -> bool:
        """Manually ban an IP address"""
        if ip not in banned_ips:
            banned_ips.add(ip)
            logger.info(f"Manually banned IP: {ip}")
            return True
        return False
