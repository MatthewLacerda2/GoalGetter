"""Add student_id to goals

Revision ID: abc123def456
Revises: ff082df0ad4a
Create Date: 2025-01-02 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'abc123def456'
down_revision: Union[str, Sequence[str], None] = 'ff082df0ad4a'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add student_id column to goals table to support multiple goals per student."""
    
    # Add student_id column as UUID (nullable initially for safety, but database has 0 users)
    op.add_column('goals', sa.Column('student_id', postgresql.UUID(as_uuid=False), nullable=False))
    
    # Add foreign key constraint
    op.create_foreign_key(
        'fk_goals_student_id',
        'goals',
        'students',
        ['student_id'],
        ['id'],
        ondelete='CASCADE'
    )
    
    # Add index for student_id
    op.create_index('idx_goal_student_id', 'goals', ['student_id'])
    
    # Make goal_id and current_objective_id nullable on students table
    # (in case user has no goals)
    op.alter_column('students', 'goal_id', nullable=True)
    op.alter_column('students', 'goal_name', nullable=True)
    op.alter_column('students', 'current_objective_id', nullable=True)
    op.alter_column('students', 'current_objective_name', nullable=True)


def downgrade() -> None:
    """Remove student_id column from goals table."""
    
    # Make goal_id and current_objective_id non-nullable again on students table
    op.alter_column('students', 'current_objective_name', nullable=False)
    op.alter_column('students', 'current_objective_id', nullable=False)
    op.alter_column('students', 'goal_name', nullable=False)
    op.alter_column('students', 'goal_id', nullable=False)
    
    # Drop index
    op.drop_index('idx_goal_student_id', 'goals')
    
    # Drop foreign key constraint
    op.drop_constraint('fk_goals_student_id', 'goals', type_='foreignkey')
    
    # Drop column
    op.drop_column('goals', 'student_id')
