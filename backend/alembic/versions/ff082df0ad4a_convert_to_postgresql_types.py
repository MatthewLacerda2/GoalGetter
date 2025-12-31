"""Convert to PostgreSQL-specific types

Revision ID: ff082df0ad4a
Revises: ff2082ff1f6e
Create Date: 2025-01-01 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'ff082df0ad4a'
down_revision: Union[str, Sequence[str], None] = 'ff2082ff1f6e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema to use PostgreSQL-specific types."""
    
    # Convert all UUID columns from String(36) to UUID type
    # Goals table
    op.execute('ALTER TABLE goals ALTER COLUMN id TYPE UUID USING id::UUID')
    
    # Achievements table
    op.execute('ALTER TABLE achievements ALTER COLUMN id TYPE UUID USING id::UUID')
    op.execute('ALTER TABLE achievements ALTER COLUMN goal_id TYPE UUID USING goal_id::UUID')
    
    # Objectives table
    op.execute('ALTER TABLE objectives ALTER COLUMN id TYPE UUID USING id::UUID')
    op.execute('ALTER TABLE objectives ALTER COLUMN goal_id TYPE UUID USING goal_id::UUID')
    
    # Multiple choice questions table
    op.execute('ALTER TABLE multiple_choice_questions ALTER COLUMN id TYPE UUID USING id::UUID')
    op.execute('ALTER TABLE multiple_choice_questions ALTER COLUMN objective_id TYPE UUID USING objective_id::UUID')
    
    # Multiple choice answers table
    op.execute('ALTER TABLE multiple_choice_answers ALTER COLUMN id TYPE UUID USING id::UUID')
    op.execute('ALTER TABLE multiple_choice_answers ALTER COLUMN question_id TYPE UUID USING question_id::UUID')
    op.execute('ALTER TABLE multiple_choice_answers ALTER COLUMN student_id TYPE UUID USING student_id::UUID')
    
    # Objective notes table
    op.execute('ALTER TABLE objective_notes ALTER COLUMN id TYPE UUID USING id::UUID')
    op.execute('ALTER TABLE objective_notes ALTER COLUMN objective_id TYPE UUID USING objective_id::UUID')
    
    # Resources table
    op.execute('ALTER TABLE resources ALTER COLUMN id TYPE UUID USING id::UUID')
    op.execute('ALTER TABLE resources ALTER COLUMN goal_id TYPE UUID USING goal_id::UUID')
    op.execute('ALTER TABLE resources ALTER COLUMN objective_id TYPE UUID USING objective_id::UUID')
    
    # Students table
    op.execute('ALTER TABLE students ALTER COLUMN id TYPE UUID USING id::UUID')
    op.execute('ALTER TABLE students ALTER COLUMN goal_id TYPE UUID USING goal_id::UUID')
    op.execute('ALTER TABLE students ALTER COLUMN current_objective_id TYPE UUID USING current_objective_id::UUID')
    
    # Subjective questions table
    op.execute('ALTER TABLE subjective_questions ALTER COLUMN id TYPE UUID USING id::UUID')
    op.execute('ALTER TABLE subjective_questions ALTER COLUMN objective_id TYPE UUID USING objective_id::UUID')
    
    # Subjective answers table
    op.execute('ALTER TABLE subjective_answers ALTER COLUMN id TYPE UUID USING id::UUID')
    op.execute('ALTER TABLE subjective_answers ALTER COLUMN question_id TYPE UUID USING question_id::UUID')
    op.execute('ALTER TABLE subjective_answers ALTER COLUMN student_id TYPE UUID USING student_id::UUID')
    
    # Chat messages table
    op.execute('ALTER TABLE chat_messages ALTER COLUMN id TYPE UUID USING id::UUID')
    op.execute('ALTER TABLE chat_messages ALTER COLUMN student_id TYPE UUID USING student_id::UUID')
    
    # Player achievements table
    op.execute('ALTER TABLE player_achievements ALTER COLUMN id TYPE UUID USING id::UUID')
    op.execute('ALTER TABLE player_achievements ALTER COLUMN student_id TYPE UUID USING student_id::UUID')
    op.execute('ALTER TABLE player_achievements ALTER COLUMN achievement_id TYPE UUID USING achievement_id::UUID')
    
    # Streak days table
    op.execute('ALTER TABLE streak_days ALTER COLUMN id TYPE UUID USING id::UUID')
    op.execute('ALTER TABLE streak_days ALTER COLUMN student_id TYPE UUID USING student_id::UUID')
    
    # Student contexts table
    op.execute('ALTER TABLE student_contexts ALTER COLUMN id TYPE UUID USING id::UUID')
    op.execute('ALTER TABLE student_contexts ALTER COLUMN student_id TYPE UUID USING student_id::UUID')
    op.execute('ALTER TABLE student_contexts ALTER COLUMN goal_id TYPE UUID USING goal_id::UUID')
    op.execute('ALTER TABLE student_contexts ALTER COLUMN objective_id TYPE UUID USING objective_id::UUID')
    
    # Convert all DateTime columns to TIMESTAMPTZ
    op.execute('ALTER TABLE goals ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE \'UTC\'')
    
    op.execute('ALTER TABLE objectives ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE \'UTC\'')
    op.execute('ALTER TABLE objectives ALTER COLUMN last_updated_at TYPE TIMESTAMPTZ USING last_updated_at AT TIME ZONE \'UTC\'')
    
    op.execute('ALTER TABLE multiple_choice_questions ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE \'UTC\'')
    
    op.execute('ALTER TABLE multiple_choice_answers ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE \'UTC\'')
    op.execute('ALTER TABLE multiple_choice_answers ALTER COLUMN last_updated_at TYPE TIMESTAMPTZ USING last_updated_at AT TIME ZONE \'UTC\'')
    
    op.execute('ALTER TABLE objective_notes ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE \'UTC\'')
    
    op.execute('ALTER TABLE resources ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE \'UTC\'')
    
    op.execute('ALTER TABLE students ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE \'UTC\'')
    op.execute('ALTER TABLE students ALTER COLUMN last_login TYPE TIMESTAMPTZ USING last_login AT TIME ZONE \'UTC\'')
    
    op.execute('ALTER TABLE subjective_questions ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE \'UTC\'')
    
    op.execute('ALTER TABLE subjective_answers ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE \'UTC\'')
    op.execute('ALTER TABLE subjective_answers ALTER COLUMN last_updated_at TYPE TIMESTAMPTZ USING last_updated_at AT TIME ZONE \'UTC\'')
    
    op.execute('ALTER TABLE chat_messages ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE \'UTC\'')
    
    op.execute('ALTER TABLE player_achievements ALTER COLUMN achieved_at TYPE TIMESTAMPTZ USING achieved_at AT TIME ZONE \'UTC\'')
    
    op.execute('ALTER TABLE streak_days ALTER COLUMN date_time TYPE TIMESTAMPTZ USING date_time AT TIME ZONE \'UTC\'')
    
    op.execute('ALTER TABLE student_contexts ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE \'UTC\'')
    
    # Add check constraints
    op.execute('ALTER TABLE students ADD CONSTRAINT check_current_streak_non_negative CHECK (current_streak >= 0)')
    op.execute('ALTER TABLE students ADD CONSTRAINT check_longest_streak_non_negative CHECK (longest_streak >= 0)')
    op.execute('ALTER TABLE students ADD CONSTRAINT check_overall_xp_non_negative CHECK (overall_xp >= 0)')
    
    op.execute('ALTER TABLE objectives ADD CONSTRAINT check_percentage_completed_range CHECK (percentage_completed >= 0 AND percentage_completed <= 100)')
    
    op.execute('ALTER TABLE multiple_choice_questions ADD CONSTRAINT check_correct_answer_index_range CHECK (correct_answer_index >= 0 AND correct_answer_index <= 3)')
    
    op.execute('ALTER TABLE multiple_choice_answers ADD CONSTRAINT check_student_answer_index_range CHECK (student_answer_index >= 0 AND student_answer_index <= 3)')
    
    # Add indexes
    op.create_index('idx_student_goal_id', 'students', ['goal_id'])
    op.create_index('idx_student_current_objective_id', 'students', ['current_objective_id'])
    
    op.create_index('idx_objective_goal_id', 'objectives', ['goal_id'])
    
    op.create_index('idx_resource_goal_id', 'resources', ['goal_id'])
    op.create_index('idx_resource_objective_id', 'resources', ['objective_id'])
    
    op.create_index('idx_achievement_goal_id', 'achievements', ['goal_id'])
    
    op.create_index('idx_chat_message_student_created', 'chat_messages', ['student_id', 'created_at'])
    
    op.create_index('idx_student_context_student_id', 'student_contexts', ['student_id'])
    op.create_index('idx_student_context_goal_id', 'student_contexts', ['goal_id'])
    op.create_index('idx_student_context_objective_id', 'student_contexts', ['objective_id'])
    
    op.create_index('idx_objective_note_objective_id', 'objective_notes', ['objective_id'])
    
    op.create_index('idx_mcq_objective_id', 'multiple_choice_questions', ['objective_id'])
    
    op.create_index('idx_mca_question_id', 'multiple_choice_answers', ['question_id'])
    op.create_index('idx_mca_student_id', 'multiple_choice_answers', ['student_id'])
    
    op.create_index('idx_sq_objective_id', 'subjective_questions', ['objective_id'])
    
    op.create_index('idx_sa_question_id', 'subjective_answers', ['question_id'])
    op.create_index('idx_sa_student_id', 'subjective_answers', ['student_id'])
    
    op.create_index('idx_streak_day_student_date', 'streak_days', ['student_id', 'date_time'])
    
    op.create_index('idx_player_achievement_student_id', 'player_achievements', ['student_id'])
    op.create_index('idx_player_achievement_achievement_id', 'player_achievements', ['achievement_id'])
    
    # Check if learn_infos table exists (it might not be in the initial migration)
    # If it exists, convert it too
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    if 'learn_infos' in inspector.get_table_names():
        op.execute('ALTER TABLE learn_infos ALTER COLUMN id TYPE UUID USING id::UUID')
        op.execute('ALTER TABLE learn_infos ALTER COLUMN objective_id TYPE UUID USING objective_id::UUID')
        op.execute('ALTER TABLE learn_infos ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE \'UTC\'')
        op.create_index('idx_learn_info_objective_id', 'learn_infos', ['objective_id'])


def downgrade() -> None:
    """Downgrade schema back to generic types."""
    
    # Drop indexes
    op.drop_index('idx_player_achievement_achievement_id', 'player_achievements')
    op.drop_index('idx_player_achievement_student_id', 'player_achievements')
    op.drop_index('idx_streak_day_student_date', 'streak_days')
    op.drop_index('idx_sa_student_id', 'subjective_answers')
    op.drop_index('idx_sa_question_id', 'subjective_answers')
    op.drop_index('idx_sq_objective_id', 'subjective_questions')
    op.drop_index('idx_mca_student_id', 'multiple_choice_answers')
    op.drop_index('idx_mca_question_id', 'multiple_choice_answers')
    op.drop_index('idx_mcq_objective_id', 'multiple_choice_questions')
    op.drop_index('idx_objective_note_objective_id', 'objective_notes')
    op.drop_index('idx_student_context_objective_id', 'student_contexts')
    op.drop_index('idx_student_context_goal_id', 'student_contexts')
    op.drop_index('idx_student_context_student_id', 'student_contexts')
    op.drop_index('idx_chat_message_student_created', 'chat_messages')
    op.drop_index('idx_achievement_goal_id', 'achievements')
    op.drop_index('idx_resource_objective_id', 'resources')
    op.drop_index('idx_resource_goal_id', 'resources')
    op.drop_index('idx_objective_goal_id', 'objectives')
    op.drop_index('idx_student_current_objective_id', 'students')
    op.drop_index('idx_student_goal_id', 'students')
    
    # Drop check constraints
    op.execute('ALTER TABLE multiple_choice_answers DROP CONSTRAINT check_student_answer_index_range')
    op.execute('ALTER TABLE multiple_choice_questions DROP CONSTRAINT check_correct_answer_index_range')
    op.execute('ALTER TABLE objectives DROP CONSTRAINT check_percentage_completed_range')
    op.execute('ALTER TABLE students DROP CONSTRAINT check_overall_xp_non_negative')
    op.execute('ALTER TABLE students DROP CONSTRAINT check_longest_streak_non_negative')
    op.execute('ALTER TABLE students DROP CONSTRAINT check_current_streak_non_negative')
    
    # Convert TIMESTAMPTZ back to TIMESTAMP
    op.execute('ALTER TABLE student_contexts ALTER COLUMN created_at TYPE TIMESTAMP USING created_at')
    op.execute('ALTER TABLE streak_days ALTER COLUMN date_time TYPE TIMESTAMP USING date_time')
    op.execute('ALTER TABLE player_achievements ALTER COLUMN achieved_at TYPE TIMESTAMP USING achieved_at')
    op.execute('ALTER TABLE chat_messages ALTER COLUMN created_at TYPE TIMESTAMP USING created_at')
    op.execute('ALTER TABLE subjective_answers ALTER COLUMN last_updated_at TYPE TIMESTAMP USING last_updated_at')
    op.execute('ALTER TABLE subjective_answers ALTER COLUMN created_at TYPE TIMESTAMP USING created_at')
    op.execute('ALTER TABLE subjective_questions ALTER COLUMN created_at TYPE TIMESTAMP USING created_at')
    op.execute('ALTER TABLE students ALTER COLUMN last_login TYPE TIMESTAMP USING last_login')
    op.execute('ALTER TABLE students ALTER COLUMN created_at TYPE TIMESTAMP USING created_at')
    op.execute('ALTER TABLE resources ALTER COLUMN created_at TYPE TIMESTAMP USING created_at')
    op.execute('ALTER TABLE objective_notes ALTER COLUMN created_at TYPE TIMESTAMP USING created_at')
    op.execute('ALTER TABLE multiple_choice_answers ALTER COLUMN last_updated_at TYPE TIMESTAMP USING last_updated_at')
    op.execute('ALTER TABLE multiple_choice_answers ALTER COLUMN created_at TYPE TIMESTAMP USING created_at')
    op.execute('ALTER TABLE multiple_choice_questions ALTER COLUMN created_at TYPE TIMESTAMP USING created_at')
    op.execute('ALTER TABLE objectives ALTER COLUMN last_updated_at TYPE TIMESTAMP USING last_updated_at')
    op.execute('ALTER TABLE objectives ALTER COLUMN created_at TYPE TIMESTAMP USING created_at')
    op.execute('ALTER TABLE goals ALTER COLUMN created_at TYPE TIMESTAMP USING created_at')
    
    # Convert UUID back to String(36)
    op.execute('ALTER TABLE student_contexts ALTER COLUMN objective_id TYPE VARCHAR(36) USING objective_id::TEXT')
    op.execute('ALTER TABLE student_contexts ALTER COLUMN goal_id TYPE VARCHAR(36) USING goal_id::TEXT')
    op.execute('ALTER TABLE student_contexts ALTER COLUMN student_id TYPE VARCHAR(36) USING student_id::TEXT')
    op.execute('ALTER TABLE student_contexts ALTER COLUMN id TYPE VARCHAR(36) USING id::TEXT')
    
    op.execute('ALTER TABLE streak_days ALTER COLUMN student_id TYPE VARCHAR(36) USING student_id::TEXT')
    op.execute('ALTER TABLE streak_days ALTER COLUMN id TYPE VARCHAR(36) USING id::TEXT')
    
    op.execute('ALTER TABLE player_achievements ALTER COLUMN achievement_id TYPE VARCHAR(36) USING achievement_id::TEXT')
    op.execute('ALTER TABLE player_achievements ALTER COLUMN student_id TYPE VARCHAR(36) USING student_id::TEXT')
    op.execute('ALTER TABLE player_achievements ALTER COLUMN id TYPE VARCHAR(36) USING id::TEXT')
    
    op.execute('ALTER TABLE chat_messages ALTER COLUMN student_id TYPE VARCHAR(36) USING student_id::TEXT')
    op.execute('ALTER TABLE chat_messages ALTER COLUMN id TYPE VARCHAR(36) USING id::TEXT')
    
    op.execute('ALTER TABLE subjective_answers ALTER COLUMN student_id TYPE VARCHAR(36) USING student_id::TEXT')
    op.execute('ALTER TABLE subjective_answers ALTER COLUMN question_id TYPE VARCHAR(36) USING question_id::TEXT')
    op.execute('ALTER TABLE subjective_answers ALTER COLUMN id TYPE VARCHAR(36) USING id::TEXT')
    
    op.execute('ALTER TABLE subjective_questions ALTER COLUMN objective_id TYPE VARCHAR(36) USING objective_id::TEXT')
    op.execute('ALTER TABLE subjective_questions ALTER COLUMN id TYPE VARCHAR(36) USING id::TEXT')
    
    op.execute('ALTER TABLE students ALTER COLUMN current_objective_id TYPE VARCHAR(36) USING current_objective_id::TEXT')
    op.execute('ALTER TABLE students ALTER COLUMN goal_id TYPE VARCHAR(36) USING goal_id::TEXT')
    op.execute('ALTER TABLE students ALTER COLUMN id TYPE VARCHAR(36) USING id::TEXT')
    
    op.execute('ALTER TABLE resources ALTER COLUMN objective_id TYPE VARCHAR(36) USING objective_id::TEXT')
    op.execute('ALTER TABLE resources ALTER COLUMN goal_id TYPE VARCHAR(36) USING goal_id::TEXT')
    op.execute('ALTER TABLE resources ALTER COLUMN id TYPE VARCHAR(36) USING id::TEXT')
    
    op.execute('ALTER TABLE objective_notes ALTER COLUMN objective_id TYPE VARCHAR(36) USING objective_id::TEXT')
    op.execute('ALTER TABLE objective_notes ALTER COLUMN id TYPE VARCHAR(36) USING id::TEXT')
    
    op.execute('ALTER TABLE multiple_choice_answers ALTER COLUMN student_id TYPE VARCHAR(36) USING student_id::TEXT')
    op.execute('ALTER TABLE multiple_choice_answers ALTER COLUMN question_id TYPE VARCHAR(36) USING question_id::TEXT')
    op.execute('ALTER TABLE multiple_choice_answers ALTER COLUMN id TYPE VARCHAR(36) USING id::TEXT')
    
    op.execute('ALTER TABLE multiple_choice_questions ALTER COLUMN objective_id TYPE VARCHAR(36) USING objective_id::TEXT')
    op.execute('ALTER TABLE multiple_choice_questions ALTER COLUMN id TYPE VARCHAR(36) USING id::TEXT')
    
    op.execute('ALTER TABLE objectives ALTER COLUMN goal_id TYPE VARCHAR(36) USING goal_id::TEXT')
    op.execute('ALTER TABLE objectives ALTER COLUMN id TYPE VARCHAR(36) USING id::TEXT')
    
    op.execute('ALTER TABLE achievements ALTER COLUMN goal_id TYPE VARCHAR(36) USING goal_id::TEXT')
    op.execute('ALTER TABLE achievements ALTER COLUMN id TYPE VARCHAR(36) USING id::TEXT')
    
    op.execute('ALTER TABLE goals ALTER COLUMN id TYPE VARCHAR(36) USING id::TEXT')
    
    # Check if learn_infos table exists and downgrade it
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    if 'learn_infos' in inspector.get_table_names():
        op.drop_index('idx_learn_info_objective_id', 'learn_infos')
        op.execute('ALTER TABLE learn_infos ALTER COLUMN created_at TYPE TIMESTAMP USING created_at')
        op.execute('ALTER TABLE learn_infos ALTER COLUMN objective_id TYPE VARCHAR(36) USING objective_id::TEXT')
        op.execute('ALTER TABLE learn_infos ALTER COLUMN id TYPE VARCHAR(36) USING id::TEXT')

