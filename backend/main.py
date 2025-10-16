import logging
from datetime import datetime
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from backend.api.v1.endpoints import router as api_v1_router
from backend.core.logging_middleware import LoggingMiddleware
from backend.core.ip_ban_middleware import IPBanMiddleware
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from fastapi.responses import PlainTextResponse

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(name)s - %(message)s"
)

logger = logging.getLogger(__name__)

app = FastAPI(
    title="GoalGetter API",
    description="API for the GoalGetter app",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)

# Add IP ban middleware FIRST (before other middleware)
app.add_middleware(IPBanMiddleware, ban_duration_minutes=60)

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

app.add_middleware(LoggingMiddleware)
app.include_router(api_v1_router, prefix="/api/v1")

@app.get("/")
async def root(request: Request):
    return {"message": "Welcome to GoalGetter API"}

@app.get("/api/v1/security/bans")
async def get_ban_status():
    """Get current ban statistics (for monitoring purposes)"""
    from backend.core.ip_ban_middleware import IPBanMiddleware
    return {
        "banned_count": IPBanMiddleware.get_banned_count(),
        "banned_ips": list(IPBanMiddleware.get_banned_ips()),
    }

@app.post("/api/v1/security/ban")
async def ban_ip_endpoint(request: Request, ip_to_ban: str):
    """Manually ban an IP address (server-only endpoint)"""
    # Get the requester's IP
    requester_ip = request.client.host
    
    # Only allow localhost/127.0.0.1 to ban IPs
    if requester_ip not in ["127.0.0.1", "localhost", "::1", "192.168.15.6"]:
        raise HTTPException(
            status_code=403, 
            detail="Only the server can ban IP addresses"
        )
    
    # Ban the IP
    success = IPBanMiddleware.ban_ip(ip_to_ban)
    
    if success:
        return {
            "message": f"IP {ip_to_ban} has been banned", 
            "success": True,
            "banned_count": IPBanMiddleware.get_banned_count()
        }
    else:
        return {
            "message": f"IP {ip_to_ban} was already banned", 
            "success": False,
            "banned_count": IPBanMiddleware.get_banned_count()
        }

SECURITY_TXT = "Contact: matheus.l1996@gmail.com\n"

@app.get("/.well-known/security.txt", response_class=PlainTextResponse)
async def security_txt():
    return SECURITY_TXT

# optional fallback if someone requests /security.txt directly
@app.get("/security.txt", response_class=PlainTextResponse)
async def security_txt_fallback():
    return SECURITY_TXT
