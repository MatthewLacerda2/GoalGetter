"""students.language

The language the student chose in the app (#172), one of `core/language.py`'s
two-letter codes. Nullable, with no default: a student who signed up before
this column has not told us yet, and his next request from the app fills it
(`core/security.py`). A backfill would have to guess, which is what the column
exists to stop.

Revision ID: 9d2d5cc35ded
Revises: a3d8362bfdd8
Create Date: 2026-09-26 17:03:57.587905

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "9d2d5cc35ded"
down_revision: str | Sequence[str] | None = "a3d8362bfdd8"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("students", sa.Column("language", sa.String(length=2), nullable=True))


def downgrade() -> None:
    op.drop_column("students", "language")
