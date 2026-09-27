"""refresh_tokens.token holds a SHA-256, not the token

From #218 the app's refresh token is never stored: the column holds its SHA-256
in hex, and every lookup hashes what was presented (`services/auth/token_rotation.py`).
No column changes. This hashes the rows already there, in place, with the same
function, so nobody is signed out by the deploy and no plaintext token is left in
the table. A row that is already 64 hex characters is a digest and is left alone.

Downgrade is a no-op: a digest cannot be turned back into its token. The older code
would simply never find these rows, and each student would sign in again once.

Revision ID: 36809274dc7d
Revises: 33c6d4ee703f
Create Date: 2026-09-27 00:40:00.000000

"""

from collections.abc import Sequence

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "36809274dc7d"
down_revision: str | Sequence[str] | None = "33c6d4ee703f"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        "UPDATE refresh_tokens "
        "SET token = encode(sha256(convert_to(token, 'UTF8')), 'hex') "
        "WHERE token !~ '^[0-9a-f]{64}$'"
    )


def downgrade() -> None:
    pass
