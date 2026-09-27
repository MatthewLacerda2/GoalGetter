"""Every route the app serves, for tests that sweep them all (#207, #274).

Read the way the OpenAPI generator reads them: since FastAPI 0.137 `app.routes`
holds an included router as one opaque entry, so walking it finds only the
routes declared on the app itself - three of them, for a check that walks it
(#274). `iter_route_contexts` walks the tree.
"""

import re
import uuid

from fastapi.routing import APIRoute, iter_route_contexts

from backend.main import app

_PARAMETER = re.compile(r"\{[^}]+\}")


def endpoints() -> list[tuple[str, str]]:
    """Every method and path the app serves, the docs aside (they are Starlette
    routes, not API routes)."""
    return sorted(
        (method, context.path)
        for context in iter_route_contexts(app.routes)
        if isinstance(context.original_route, APIRoute)
        if context.path
        for method in context.methods or ()
    )


def with_made_up_ids(path: str) -> str:
    """The path with a fresh UUID in each parameter: a request to it names
    nothing that exists."""
    return _PARAMETER.sub(str(uuid.uuid4()), path)
