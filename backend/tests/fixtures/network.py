"""The default suite reaches nothing but its own test database (#176, #205).

Every test mocks Gemini and YouTube and hands the jobs the test's session, and
that is only true until someone forgets one. Three layers make it mechanical,
outermost first:

1. **No route.** `make back-test` runs the suite in a container that shares the
   network namespace of the run's own Postgres, which has no network of its own
   (`tools/test-db.sh`). Nothing else exists from inside: not the host's live
   database on 5434, not the internet, not DNS. CI runs on the runner instead,
   where there is no live database to reach, and relies on the next two.
2. **No real DATABASE_URL.** Before anything imports the settings, this module
   replaces DATABASE_URL with a host under `.invalid`, which never resolves
   (RFC 2606). So `backend.core.database.AsyncSessionLocal` - what the chain, the
   nightly run and the embeddings job open for themselves - fails loudly when a
   test forgets to patch it, instead of writing wherever DATABASE_URL points.
3. **This guard**, installed the moment this module is imported. It is the first
   plugin the root conftest loads, so that is before any app or test module is,
   and a lookup made at import time meets it too. It refuses:
   - a DNS lookup of any name but the test database's host;
   - a TCP connect, or a UDP sendto, to anything but the test database's
     host:port - loopback included, since the live database listens there;
   - starting a process (`subprocess`, `os.system`, `posix_spawn`): a child
     process inherits none of this.

A refused attempt raises, and is also **recorded**, because raising alone is not
enough: link validation catches every error and quietly drops the link, so a
leaking test there would stay green. The per-test check fails the test that made
the attempt, whoever swallowed the exception; an attempt made while the tests
were being imported stops the run.

The `live` suite (`make test-live`, `pytest --live`) is the one place real calls
are the point, so there the guard comes down at configure time. DATABASE_URL
stays unresolvable there too: no live test needs a database.
"""

import ipaddress
import os
import socket
import subprocess
import sys
from urllib.parse import urlsplit

import pytest

UNREACHABLE_HOST = "database-url-is-not-for-tests.invalid"
os.environ["DATABASE_URL"] = f"postgresql+asyncpg://nobody:nothing@{UNREACHABLE_HOST}/none"

from backend.core.config import settings  # noqa: E402 - must follow the line above

ATTEMPTS: list[str] = []


class NetworkCallInDefaultSuite(RuntimeError):
    """Not an OSError on purpose: the clients under test retry or swallow those."""


def refuse(what: str, kind: str = "reach"):
    ATTEMPTS.append(what)
    if what == UNREACHABLE_HOST:
        raise NetworkCallInDefaultSuite(
            "a test opened a session on DATABASE_URL (backend.core.database), which "
            "the tests never have. Hand the code the test's session: patch its "
            "AsyncSessionLocal (fixtures/jobs.py `Session`) or override get_db."
        )
    raise NetworkCallInDefaultSuite(
        f"the default suite tried to {kind} {what!r}. Mock the call, or mark the "
        "test `@pytest.mark.live` and run it with `make test-live`."
    )


def _is_ip(host: str) -> bool:
    try:
        ipaddress.ip_address(host)
    except ValueError:
        return False
    return True


class Guard:
    """The patched doors, and the real ones to put back."""

    def __init__(self):
        self.installed = False
        self.modules_before = frozenset(sys.modules)
        database = urlsplit(settings.TEST_DATABASE_URL or "")
        self.host = database.hostname
        self.endpoints: set[tuple[str, int]] = set()
        if self.host:
            port = database.port or 5432
            for *_, address in socket.getaddrinfo(self.host, port, type=socket.SOCK_STREAM):
                self.endpoints.add((address[0], port))

    def lookup_allowed(self, host) -> bool:
        host = host.decode() if isinstance(host, bytes) else host
        return not host or host == self.host or _is_ip(host)

    def check(self, sock, address):
        if sock.family in (socket.AF_INET, socket.AF_INET6):
            if (address[0], address[1]) not in self.endpoints:
                refuse(f"{address[0]}:{address[1]}")

    def install(self):
        self.real = (
            socket.getaddrinfo,
            socket.socket.connect,
            socket.socket.connect_ex,
            socket.socket.sendto,
            socket.socket.sendmsg,
            subprocess.Popen._execute_child,
            os.system,
            os.posix_spawn,
            os.posix_spawnp,
        )
        getaddrinfo, connect, connect_ex, sendto, sendmsg = self.real[:5]
        guard = self

        def guarded_getaddrinfo(host, *args, **kwargs):
            if not guard.lookup_allowed(host):
                refuse(host.decode() if isinstance(host, bytes) else host)
            return getaddrinfo(host, *args, **kwargs)

        def guarded_connect(sock, address):
            guard.check(sock, address)
            return connect(sock, address)

        def guarded_connect_ex(sock, address):
            guard.check(sock, address)
            return connect_ex(sock, address)

        def guarded_sendto(sock, data, *args):
            guard.check(sock, args[-1])
            return sendto(sock, data, *args)

        def guarded_sendmsg(sock, buffers, *args):
            if len(args) >= 3:
                guard.check(sock, args[2])
            return sendmsg(sock, buffers, *args)

        def no_process(*args, **kwargs):
            refuse(repr(args[1] if len(args) > 1 else args), kind="start a process:")

        socket.getaddrinfo = guarded_getaddrinfo
        socket.socket.connect = guarded_connect
        socket.socket.connect_ex = guarded_connect_ex
        socket.socket.sendto = guarded_sendto
        socket.socket.sendmsg = guarded_sendmsg
        subprocess.Popen._execute_child = no_process
        os.system = os.posix_spawn = os.posix_spawnp = no_process
        self.installed = True

    def uninstall(self):
        if not self.installed:
            return
        (
            socket.getaddrinfo,
            socket.socket.connect,
            socket.socket.connect_ex,
            socket.socket.sendto,
            socket.socket.sendmsg,
            subprocess.Popen._execute_child,
            os.system,
            os.posix_spawn,
            os.posix_spawnp,
        ) = self.real
        self.installed = False


GUARD = Guard()
GUARD.install()


@pytest.hookimpl
def pytest_configure(config):
    if config.getoption("--live"):
        GUARD.uninstall()


@pytest.hookimpl
def pytest_collection_finish(session):
    if ATTEMPTS:
        pytest.exit(
            f"importing the tests tried to reach {ATTEMPTS} - a module-level call "
            "that must be mocked or moved into the test.",
            returncode=pytest.ExitCode.TESTS_FAILED,
        )


@pytest.hookimpl
def pytest_unconfigure(config):
    GUARD.uninstall()


@pytest.fixture(scope="session")
def network_attempts():
    """The places a test tried to reach. Empty for the whole default run."""
    return ATTEMPTS


@pytest.fixture(autouse=True)
def no_network_call(network_attempts):
    """Fail the test that tried, even when the code under test ate the error."""
    network_attempts.clear()
    yield
    tried = list(network_attempts)
    network_attempts.clear()
    assert not tried, f"this test tried to reach the network: {tried}"
