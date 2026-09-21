"""CORS origins: production stays exact, a DEV_LOGIN backend admits dev origins."""
import re
import pytest
from backend.core.cors import cors_origin_regex


def admits(origin: str, dev_login: bool) -> bool:
    pattern = cors_origin_regex(dev_login)
    return pattern is not None and re.fullmatch(pattern, origin) is not None


@pytest.mark.parametrize("origin", [
    "http://localhost:8091", "http://127.0.0.1:8090", "http://[::1]:5000",
    "http://100.101.102.103:8090", "http://archbox.tail1234.ts.net:8090",
])
def test_dev_backend_admits_dev_origins(origin):
    assert admits(origin, dev_login=True)


@pytest.mark.parametrize("origin", [
    "https://evil.example", "http://localhost.evil.example:8090",
    "http://100.200.1.1:8090", "http://192.168.0.10:8090", "http://evil.ts.net.example",
])
def test_dev_backend_still_refuses_other_origins(origin):
    assert not admits(origin, dev_login=True)


def test_production_admits_no_extra_origin():
    assert cors_origin_regex(dev_login=False) is None
