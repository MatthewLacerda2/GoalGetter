"""Every route answers 401 to a request with no token, unless it is listed here (#207).

Driven by `app.routes`, so a route added tomorrow is checked tomorrow without
anyone writing its 401 test - which is how it was done before: one copy per
route, and a route whose copy was forgotten was a route nobody checked. A new
route that is meant to be open goes into `PUBLIC`, with the reason, on purpose.
"""

import pytest

from backend.core.errors.codes import ErrorCode
from backend.tests.fixtures.routes import endpoints, with_made_up_ids

# Open to a caller with no token, and why.
PUBLIC = {
    ("POST", "/api/v1/auth/login"): "how a token is got",
    ("POST", "/api/v1/auth/dev-login"): "a fictitious sign-in; 404 unless DEV_LOGIN",
    ("POST", "/api/v1/auth/refresh"): "the refresh token in the body is the credential",
    ("POST", "/api/v1/auth/logout"): "the refresh token in the body is the credential",
    ("POST", "/api/v1/goals/objective-questions"): "onboarding comes before signing up",
    ("POST", "/api/v1/goals/study-plan"): "onboarding comes before signing up",
    ("GET", "/api/v1/check"): "the health check",
    ("GET", "/security.txt"): "a public file",
    ("GET", "/llms.txt"): "a public file",
}

PROTECTED = [endpoint for endpoint in endpoints() if endpoint not in PUBLIC]


def test_every_public_route_still_exists():
    """A route that was renamed leaves its old name here, open to nobody"""
    assert set(PUBLIC) <= set(endpoints())


def test_the_check_below_has_routes_to_check():
    """`app.routes` read wrong would make the parametrized test below vanish"""
    assert len(PROTECTED) >= len(PUBLIC)


@pytest.mark.parametrize(("method", "path"), PROTECTED, ids=[" ".join(e) for e in PROTECTED])
async def test_a_request_without_a_token_is_401(client, method, path):
    """Before the body is read and before anything is looked up: a made-up id in
    the path must not turn it into a 404 that tells a stranger what exists"""
    response = await client.request(method, with_made_up_ids(path))

    assert (response.status_code, response.json()["code"]) == (401, ErrorCode.NOT_SIGNED_IN)
