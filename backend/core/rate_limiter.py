"""Who a request is, for rate limiting (#217).

The bucket is the client's address - the student's, not the proxy's. In
production every request reaches uvicorn from nginx (the `frontend` container),
which reached it from cloudflared, so the TCP peer is nginx for everyone: keyed
on the peer, as it was, every student shared one bucket.

Cloudflare's edge writes `CF-Connecting-IP` itself, overwriting whatever the
client sent, and cloudflared and nginx pass it on untouched. So the header is
the truth when the request came through a proxy of ours, and a forgery when it
did not. Which peer is "a proxy of ours" is decided by address: nginx is always
on a private network (`PROXY_NETWORKS`: the compose network in production, loopback for
`make preview`), while a peer with a public address is a client talking to
uvicorn directly - its header is ignored and it is counted on its own address.
Left open by design: a client that reaches nginx without the tunnel can still
pick a bucket, and the only such doors are the user's own (loopback :8095 for
the production nginx, the tailnet for the preview's, the LAN for a dev backend
on 8001). Production's uvicorn publishes no port at all.

Keyed on the address, not the signed-in student: the endpoints that bill Gemini
without an account (goal onboarding) have no student to key on, and keying the
others on the student would verify the JWT a second time, here, before the
route's own `get_current_user` does. Students behind one NAT share a bucket.

An IPv6 client is keyed on its /64: one subscriber is routinely handed a whole
/64, so keying the full address would let him rotate through 2^64 buckets.

Counted per uvicorn worker. slowapi keeps its counters in process memory and
docker-compose.yml runs 4 workers; shared counters need a shared store (Redis,
Memcached), which would be a new service, and a limit that bounds the bill does
not need to be exact. The kernel spreads connections across workers, so a
client's real ceiling is between the stated limit and 4x it: 10 to 40 requests a
second by default, 20 to 80 a minute on the onboarding endpoints.
"""

import ipaddress

from slowapi import Limiter
from starlette.requests import Request

# Written by Cloudflare's edge, never by the client (see the module docstring).
CLIENT_ADDRESS_HEADER = "cf-connecting-ip"

# How much of an IPv6 address is one client: the /64 a subscriber is handed.
IPV6_CLIENT_PREFIX = 64

# Where a proxy of ours can be: loopback, and the private ranges Docker draws its
# networks from. Named rather than `is_private`, which also counts the
# documentation and benchmarking ranges.
PROXY_NETWORKS = tuple(
    ipaddress.ip_network(n)
    for n in ("127.0.0.0/8", "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "::1/128", "fc00::/7")
)


def _parse(address: str | None) -> ipaddress.IPv4Address | ipaddress.IPv6Address | None:
    try:
        return ipaddress.ip_address((address or "").strip())
    except ValueError:
        return None


def _is_proxy(address: ipaddress.IPv4Address | ipaddress.IPv6Address) -> bool:
    return any(address in network for network in PROXY_NETWORKS)


def _bucket(address: ipaddress.IPv4Address | ipaddress.IPv6Address) -> str:
    if address.version == 6:
        return str(ipaddress.ip_network(f"{address}/{IPV6_CLIENT_PREFIX}", strict=False))
    return str(address)


def client_address(request: Request) -> str:
    """The rate-limit key: the client's address, as far as it can be trusted."""
    peer_text = request.client.host if request.client else None
    peer = _parse(peer_text)
    if peer is not None and _is_proxy(peer):
        forwarded = _parse(request.headers.get(CLIENT_ADDRESS_HEADER))
        if forwarded is not None:
            return _bucket(forwarded)
    if peer is None:
        # Not an address (Starlette's TestClient says "testclient"): its own bucket.
        return peer_text or "unknown"
    return _bucket(peer)


limiter = Limiter(key_func=client_address, default_limits=["10/second"])
