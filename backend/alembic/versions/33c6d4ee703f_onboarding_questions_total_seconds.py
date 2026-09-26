"""onboarding_questions.total_seconds

How long the student spent on each onboarding question (#174), in whole
seconds, as the app measured it - named after `student_answers.total_seconds`.
Nullable, with no backfill: the answers already stored were never timed, and an
older client or an unreadable clock must lose the duration, never the answer.

Revision ID: 33c6d4ee703f
Revises: 9d2d5cc35ded
Create Date: 2026-09-26 17:20:20.966130

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "33c6d4ee703f"
down_revision: str | Sequence[str] | None = "9d2d5cc35ded"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("onboarding_questions", sa.Column("total_seconds", sa.Integer(), nullable=True))


def downgrade() -> None:
    op.drop_column("onboarding_questions", "total_seconds")
