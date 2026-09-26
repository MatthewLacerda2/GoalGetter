"""The default suite makes no network call, and knows it (#176).

`fixtures/network.py` refuses every host that is not this machine or the test
database. These tests are that claim checked from the outside: a real API host
is refused before its DNS lookup leaves the process, whether the client is a
plain socket or httpx, and the loopback the database lives on is still open.
"""

import socket

import httpx
import pytest

from backend.tests.fixtures.network import NetworkCallInDefaultSuite


def test_a_real_api_host_is_refused_before_dns(network_attempts):
    with pytest.raises(NetworkCallInDefaultSuite):
        socket.create_connection(("generativelanguage.googleapis.com", 443), timeout=1)

    assert network_attempts == ["generativelanguage.googleapis.com"]
    network_attempts.clear()


def test_an_ip_address_is_refused_at_connect(network_attempts):
    with pytest.raises(NetworkCallInDefaultSuite):
        socket.create_connection(("192.0.2.1", 443), timeout=1)

    assert network_attempts == ["192.0.2.1"]
    network_attempts.clear()


async def test_httpx_is_refused_too(network_attempts):
    async with httpx.AsyncClient() as client:
        with pytest.raises(NetworkCallInDefaultSuite):
            await client.get("https://www.googleapis.com/youtube/v3/search")

    assert network_attempts == ["www.googleapis.com"]
    network_attempts.clear()


def test_loopback_stays_open(network_attempts):
    with socket.socket() as server:
        server.bind(("127.0.0.1", 0))
        server.listen()
        socket.create_connection(server.getsockname(), timeout=1).close()

    assert network_attempts == []
