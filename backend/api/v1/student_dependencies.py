"""The FastAPI dependency that resolves the signed-in student.

It lives in api/, beside `goal_dependencies.py`, rather than in `core/security.py`
(#211): it reads the database, and core/ is the floor every layer imports, so it
imports none of them. What stays in core is the token arithmetic it builds on
(`verify_token`) and the bearer scheme (`security`).
"""

import logging

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from backend.core.database import get_db
from backend.core.errors.api_error import ApiError
from backend.core.errors.codes import ErrorCode
from backend.core.language import Language, requested_language
from backend.core.security import security, verify_token
from backend.models.student import Student
from backend.repositories.student_repository import StudentRepository

logger = logging.getLogger(__name__)


def remember_language(student: Student, language: Language | None) -> bool:
    """Mirror the language the app sent onto the student; True if it changed.
    Nothing sent leaves what is stored alone."""
    if language is None or student.language == language:
        return False
    student.language = language
    return True


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db),
    language: Language | None = Depends(requested_language),
) -> Student:
    """
    Get the current authenticated user from the JWT token, and keep his
    language up to date with the one the app sent (#172, `core/language.py`).

    **This dependency commits, on purpose (#218).** The language must reach the
    database even on a GET that commits nothing, because the nightly jobs write
    in it (`services/gemini/output_language.py`). The commit is safe here: it
    runs before the endpoint's body, so the language is the only change pending
    in the session - no endpoint's half-done work is published with it - and it
    happens only when the language changed, once per switch rather than once per
    request. Leaving it to the endpoints would make every read endpoint commit.
    """
    user = await _user_from_token(credentials, db)
    if remember_language(user, language):
        await StudentRepository(db).update(user)
        await db.commit()
    return user


async def _user_from_token(credentials: HTTPAuthorizationCredentials, db: AsyncSession) -> Student:
    """The student the token names. Only a problem with the token answers 401,
    because the app reads 401 as "your session ended" and signs the student out
    (#186). Anything else — the database down, a bug in the lookup — is left to
    raise and answers 500, which the app does not read as a sign-out."""
    payload = verify_token(credentials.credentials)
    google_id = payload.get("sub")
    if not isinstance(google_id, str) or not google_id:
        raise ApiError(ErrorCode.INVALID_TOKEN)

    student = await StudentRepository(db).get_by_google_id(google_id)
    if student is None:
        # A valid token for a student who no longer exists (the account was
        # deleted): the session really is over, so 401 — signing him out is
        # the right thing — but said, not folded into "invalid token".
        logger.warning("Token for a student who no longer exists")
        raise ApiError(ErrorCode.STUDENT_NO_LONGER_EXISTS)
    return student
