"""The default suite reaches nothing but its test database, and knows it (#176, #205).

`fixtures/network.py` refuses every lookup, connection, datagram and process
that is not the test database. These tests are that claim checked from the
outside: a real API host is refused before its DNS lookup leaves the process,
whether the client is a plain socket or httpx; loopback is closed too, because
the live database listens there; and the guard is up before the app is imported.
"""

import os
import socket
import subprocess

import httpx
import pytest

from backend.tests.fixtures.network import GUARD, NetworkCallInDefaultSuite

# The live database's port on this machine (docker-compose.yml, `postgres`).
LIVE_DATABASE = ("127.0.0.1", 5434)


def test_a_real_api_host_is_refused_before_dns(network_attempts):
    with pytest.raises(NetworkCallInDefaultSuite):
        socket.create_connection(("generativelanguage.googleapis.com", 443), timeout=1)

    assert network_attempts == ["generativelanguage.googleapis.com"]
    network_attempts.clear()


def test_an_ip_address_is_refused_at_connect(network_attempts):
    with pytest.raises(NetworkCallInDefaultSuite):
        socket.create_connection(("192.0.2.1", 443), timeout=1)

    assert network_attempts == ["192.0.2.1:443"]
    network_attempts.clear()


async def test_httpx_is_refused_too(network_attempts):
    async with httpx.AsyncClient() as client:
        with pytest.raises(NetworkCallInDefaultSuite):
            await client.get("https://www.googleapis.com/youtube/v3/search")

    assert network_attempts == ["www.googleapis.com"]
    network_attempts.clear()


def test_loopback_is_refused_even_where_a_server_listens(network_attempts):
    with socket.socket() as server:
        server.bind(("127.0.0.1", 0))
        server.listen()
        port = server.getsockname()[1]
        with pytest.raises(NetworkCallInDefaultSuite):
            socket.create_connection(("127.0.0.1", port), timeout=1)
        with pytest.raises(NetworkCallInDefaultSuite):
            socket.create_connection(LIVE_DATABASE, timeout=1)

    assert network_attempts == [f"127.0.0.1:{port}", "127.0.0.1:5434"]
    network_attempts.clear()


def test_a_udp_datagram_is_refused(network_attempts):
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as udp:
        with pytest.raises(NetworkCallInDefaultSuite):
            udp.sendto(b"x", ("192.0.2.1", 53))

    assert network_attempts == ["192.0.2.1:53"]
    network_attempts.clear()


def test_a_process_is_refused(network_attempts):
    """A child process inherits none of the guard, so none may start."""
    with pytest.raises(NetworkCallInDefaultSuite):
        subprocess.run(["true"])
    with pytest.raises(NetworkCallInDefaultSuite):
        os.system("true")

    assert len(network_attempts) == 2
    network_attempts.clear()


def test_the_guard_is_up_before_the_app_is_imported():
    """A lookup made while a module is imported meets the guard too."""
    assert GUARD.installed
    assert "backend.main" not in GUARD.modules_before
    assert "backend.core.database" not in GUARD.modules_before
