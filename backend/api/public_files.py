"""The files a crawler looks for at the site's root, not under /api/v1."""

from fastapi import APIRouter
from fastapi.responses import PlainTextResponse

from backend.llms import get_llms_txt

router = APIRouter()

SECURITY_TXT = "Contact: matheus.l1996@gmail.com\n"


@router.get("/security.txt", response_class=PlainTextResponse)
async def security_txt_fallback() -> str:
    return SECURITY_TXT


@router.get("/llms.txt", response_class=PlainTextResponse)
async def llms_txt() -> str:
    return get_llms_txt()
