"""Which browser origins may call the API.

Production is strict: the exact origins in PRODUCTION_ORIGINS and nothing else.
A dev backend (DEV_LOGIN=true) also lets through any port on loopback and on
Tailscale (a 100.64.0.0/10 address or a *.ts.net MagicDNS name), over plain
http. That is what a Flutter dev server looks like: a random or per-worktree port
on this machine, or the phone reaching this machine over Tailscale. Tying the
widening to DEV_LOGIN rather than to a separate flag keeps one switch for "this
is a dev backend", and that switch is already off in production (decided in #51).
"""

PRODUCTION_ORIGINS = ["https://goalsgetter.org", "http://localhost:8080"]

DEV_ORIGIN_REGEX = (
    r"http://("
    r"localhost|127\.0\.0\.1|\[::1\]"
    r"|100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.[0-9]{1,3}\.[0-9]{1,3}"
    r"|[a-z0-9-]+(\.[a-z0-9-]+)*\.ts\.net"
    r")(:[0-9]{1,5})?"
)


def cors_origin_regex(dev_login: bool) -> str | None:
    """The extra origin pattern CORSMiddleware accepts, or None in production.
    Starlette full-matches it against the Origin header."""
    return DEV_ORIGIN_REGEX if dev_login else None
