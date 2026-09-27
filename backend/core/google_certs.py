"""Google's signing certificates, downloaded once per the lifetime Google gives them (#258).

google-auth fetches the certificates on every verification, through whatever
transport it is handed, and a plain `google.auth.transport.requests.Request()`
caches nothing: every sign-in paid a round trip to Google before it could check
a signature. `CachedGoogleCerts` is that transport with a memory: a successful
GET is kept for as long as Google's `Cache-Control: max-age` says, less the
`Age` the response already carries, and a response with no max-age, or not a
200, is not kept.

In-process rather than google-auth's documented CacheControl session: this
serves one URL and reads one header, which is less code than the dependency, and
a miss - once every few hours - opens a fresh `requests` session, so no session
is ever shared between the worker threads verification runs on (#210).
"""

import re
import threading
from collections.abc import Mapping
from datetime import datetime, timedelta

from google.auth import transport
from google.auth.transport import requests

from backend.core import clock

_MAX_AGE = re.compile(r"(?:^|[\s,])max-age=(\d+)", re.IGNORECASE)
_UNCACHEABLE = re.compile(r"(?:^|[\s,])(?:no-store|no-cache|private)\b", re.IGNORECASE)


def _lifetime(response: transport.Response) -> int:
    """Seconds this response stays fresh from now; 0 when it must not be kept."""
    cache_control = response.headers.get("Cache-Control", "")
    max_age = _MAX_AGE.search(cache_control)
    if response.status != 200 or not max_age or _UNCACHEABLE.search(cache_control):
        return 0
    age = response.headers.get("Age", "0")
    return int(max_age.group(1)) - (int(age) if age.isdigit() else 0)


class CachedGoogleCerts(transport.Request):
    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._kept: dict[str, tuple[datetime, transport.Response]] = {}

    def __call__(
        self,
        url: str,
        method: str = "GET",
        body: bytes | None = None,
        headers: Mapping[str, str] | None = None,
        timeout: float | None = None,
        **kwargs: object,
    ) -> transport.Response:
        # Forwarded only when given, so requests' own default applies otherwise.
        if timeout is not None:
            kwargs["timeout"] = timeout
        if method != "GET" or body is not None:
            passed: transport.Response = requests.Request()(
                url, method=method, body=body, headers=headers, **kwargs
            )
            return passed
        with self._lock:
            entry = self._kept.get(url)
        if entry is not None and clock.now() < entry[0]:
            return entry[1]
        response: transport.Response = requests.Request()(
            url, method=method, headers=headers, **kwargs
        )
        lifetime = _lifetime(response)
        if lifetime > 0:
            with self._lock:
                self._kept[url] = (clock.now() + timedelta(seconds=lifetime), response)
        return response


# One per process: the certificates are Google's, the same for every student.
GOOGLE_CERTS = CachedGoogleCerts()
