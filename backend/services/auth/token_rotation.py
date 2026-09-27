"""Refresh tokens: issued at sign-in, rotated on every refresh, revoked on logout (#218).

**What is stored is a digest.** The app holds a 64-byte random token; the
`refresh_tokens.token` column holds its SHA-256, and every lookup hashes what was
presented. A leaked table is then no leaked session. SHA-256 and not bcrypt: bcrypt
is slow and salted because a password is guessable and must be looked up by the
student it belongs to. A token of 512 random bits is not guessable, so a fast
unsalted hash costs an attacker nothing he could use, and it keeps the lookup a
single indexed equality instead of a bcrypt check against every row.

**A family is a chain of ids, not a column.** A token issued at sign-in gets a random
id. The token that replaces it on a refresh gets `uuid5(FAMILY, <its id>)`, and so
on down the chain, so from any token its successor is computable and a family is
walked forward one primary-key lookup at a time. The issue asked for reuse detection
without a schema change, and this is the family expressed in data the table already
has. A side effect is a second guard on rotation: one token can only ever have one
successor, because two would share a primary key.

**A rotated token presented again is treated as stolen.** Only one party can hold
the current token; whoever presents an older one is either the thief or the student
after the thief rotated first. Either way the family is revoked from that point on,
so both are signed out and the student signs in again - the standard answer of
refresh-token rotation. The app shares one refresh between concurrent requests
(`frontend/lib/core/api/api_client.dart`), so it never replays a token itself.
"""

import hashlib
import secrets
import uuid
from datetime import timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from backend.core import clock
from backend.models.refresh_token import RefreshToken
from backend.repositories.refresh_token_repository import RefreshTokenRepository

LIFETIME = timedelta(days=30)

# The namespace a successor's id is derived in. Any fixed UUID works; changing it
# only cuts the chain between tokens issued before and after the change.
FAMILY = uuid.UUID("2ef37985-7fd6-4404-8e20-895f86c5ffe1")


def digest(token: str) -> str:
    """What the database stores, and looks up by, for `token`."""
    return hashlib.sha256(token.encode()).hexdigest()


def successor_id(token_id: uuid.UUID) -> uuid.UUID:
    """The id the token that replaces `token_id` is stored under."""
    return uuid.uuid5(FAMILY, str(token_id))


async def issue(
    db: AsyncSession, student_id: uuid.UUID, replacing: RefreshToken | None = None
) -> str:
    """Store a new token for the student and return it - the only time it exists
    in plaintext. `replacing` is the token it rotates, which makes it that
    token's successor; without it, it starts a family. Flushes; the caller commits."""
    token = secrets.token_urlsafe(64)
    await RefreshTokenRepository(db).create(
        RefreshToken(
            id=successor_id(replacing.id) if replacing else uuid.uuid4(),
            student_id=student_id,
            token=digest(token),
            expires_at=clock.now() + LIFETIME,
        )
    )
    return token


async def rotate(db: AsyncSession, token: str) -> tuple[uuid.UUID, str] | None:
    """Revoke `token` and issue its successor: (student id, new token). None when
    `token` is unknown, expired or already revoked - and when it was revoked, its
    successors are revoked too. Either way something may have been written, so the
    caller commits before answering."""
    repo = RefreshTokenRepository(db)
    presented = await repo.revoke_if_live(digest(token), clock.now())
    if presented is None:
        await _revoke_successors(repo, token)
        return None
    return presented.student_id, await issue(db, presented.student_id, replacing=presented)


async def _revoke_successors(repo: RefreshTokenRepository, token: str) -> None:
    """A revoked token came back: revoke every token issued after it in its family.
    An unknown or merely expired token has nothing to answer for."""
    presented = await repo.get_by_digest(digest(token))
    if presented is None or not presented.revoked:
        return
    next_id = successor_id(presented.id)
    while await repo.revoke(next_id):
        next_id = successor_id(next_id)


async def revoke(db: AsyncSession, token: str) -> None:
    """Logout: revoke `token` if it exists. Flushes; the caller commits."""
    repo = RefreshTokenRepository(db)
    presented = await repo.get_by_digest(digest(token))
    if presented is not None:
        await repo.revoke(presented.id)
