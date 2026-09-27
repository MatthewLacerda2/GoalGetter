import uuid
from datetime import datetime

from sqlalchemy import select, update

from backend.models.refresh_token import RefreshToken
from backend.repositories.base import BaseRepository


class RefreshTokenRepository(BaseRepository[RefreshToken]):
    """The `token` column holds a digest, never the token the app holds (#218):
    every method here takes the digest, and `services/auth/token_rotation.py` is
    the one place that computes it."""

    model = RefreshToken

    async def get_by_digest(self, digest: str) -> RefreshToken | None:
        stmt = select(RefreshToken).where(RefreshToken.token == digest)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def revoke_if_live(self, digest: str, now: datetime) -> RefreshToken | None:
        """Revoke the token if it is neither revoked nor expired, in one statement,
        and return it; None when it was not live.

        The check and the revocation are one conditional UPDATE, so two sessions
        presenting the same token cannot both pass: the second one waits on the
        first's row lock and then finds `revoked` already true (#218)."""
        stmt = (
            update(RefreshToken)
            .where(
                RefreshToken.token == digest,
                RefreshToken.revoked.is_(False),
                RefreshToken.expires_at > now,
            )
            .values(revoked=True)
            .returning(RefreshToken)
            .execution_options(populate_existing=True)
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def revoke(self, token_id: uuid.UUID) -> bool:
        """Mark one token revoked, whatever its state; False when no row has that id."""
        stmt = (
            update(RefreshToken)
            .where(RefreshToken.id == token_id)
            .values(revoked=True)
            .returning(RefreshToken.id)
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none() is not None
