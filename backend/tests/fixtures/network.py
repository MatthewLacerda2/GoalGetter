"""The default suite never reaches the network - asserted, not assumed (#176).

Every test mocks Gemini and YouTube, and that is only true until someone forgets
one. This fixture makes it mechanical: for the whole session it replaces the two
doors every client goes through - `socket.getaddrinfo` (the DNS lookup) and
`socket.socket.connect` (the TCP handshake, which asyncio and httpx use too) -
with ones that refuse any host that is not this machine or the test database.

A refused attempt raises, and is also **recorded**, because raising alone is not
enough: link validation catches every error and quietly drops the link, so a
leaking test there would stay green. The per-test check fails the test that made
the attempt, whoever swallowed the exception.

The `live` suite (`make test-live`, `pytest --live`) is the one place real calls
are the point, so there the guard is off.
"""

import ipaddress
import socket
from urllib.parse import urlsplit

import pytest

from backend.core.config import settings


class NetworkCallInDefaultSuite(RuntimeError):
    """Not an OSError on purpose: the clients under test retry or swallow those."""


def _allowed_hosts() -> set[str]:
    hosts = {"localhost"}
    database = urlsplit(settings.TEST_DATABASE_URL or "").hostname
    if database:
        hosts.add(database)
    return hosts


def _name(host) -> str | None:
    """asyncio hands getaddrinfo the host as bytes, a socket as str."""
    return host.decode() if isinstance(host, bytes) else host


def _is_local(host: str | None, allowed: set[str]) -> bool:
    if host is None or host == "" or host in allowed:
        return True
    try:
        return ipaddress.ip_address(host).is_loopback
    except ValueError:
        return False


@pytest.fixture(scope="session", autouse=True)
def network_attempts(request):
    """The hosts a test tried to reach. Empty for the whole default run."""
    attempts: list[str] = []
    if request.config.getoption("--live"):
        yield attempts
        return

    allowed = _allowed_hosts()
    real_getaddrinfo = socket.getaddrinfo
    real_connect = socket.socket.connect
    real_connect_ex = socket.socket.connect_ex

    def refuse(host):
        attempts.append(host)
        raise NetworkCallInDefaultSuite(
            f"the default suite tried to reach {host!r}. Mock the call, or mark the "
            "test `@pytest.mark.live` and run it with `make test-live`."
        )

    def getaddrinfo(host, *args, **kwargs):
        if not _is_local(_name(host), allowed):
            refuse(_name(host))
        return real_getaddrinfo(host, *args, **kwargs)

    def check(sock, address):
        if sock.family in (socket.AF_INET, socket.AF_INET6) and not _is_local(address[0], allowed):
            refuse(address[0])

    def connect(sock, address):
        check(sock, address)
        return real_connect(sock, address)

    def connect_ex(sock, address):
        check(sock, address)
        return real_connect_ex(sock, address)

    socket.getaddrinfo = getaddrinfo
    socket.socket.connect = connect
    socket.socket.connect_ex = connect_ex
    try:
        yield attempts
    finally:
        socket.getaddrinfo = real_getaddrinfo
        socket.socket.connect = real_connect
        socket.socket.connect_ex = real_connect_ex


@pytest.fixture(autouse=True)
def no_network_call(network_attempts):
    """Fail the test that tried, even when the code under test ate the error."""
    network_attempts.clear()
    yield
    tried = list(network_attempts)
    network_attempts.clear()
    assert not tried, f"this test tried to reach the network: {tried}"
