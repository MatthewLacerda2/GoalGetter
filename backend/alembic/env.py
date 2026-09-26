from logging.config import fileConfig

from alembic import context
from pgvector.sqlalchemy import Vector
from sqlalchemy import engine_from_config, pool

# this is the Alembic Config object, which provides
# access to the values within the .ini file in use.
config = context.config

# Interpret the config file for Python logging.
# This line sets up loggers basically.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# add your model's MetaData object here
# for 'autogenerate' support
# Importing the package registers every model on Base.metadata (see
# backend/models/__init__.py), which is what autogenerate reads.
from backend.models import Base  # noqa: E402 - must follow the config block above

target_metadata = Base.metadata


def database_url() -> str:
    """The migration target, as a sync URL.

    One place reads it: DATABASE_URL from the settings (the environment first,
    then .env), which is how every other process here finds the database. It
    arrives in asyncpg form because the app is async; alembic drives a plain
    DBAPI, so it is handed to psycopg2 instead.
    """
    from backend.core.config import settings

    url = settings.DATABASE_URL
    if url.startswith("postgresql+asyncpg://"):
        url = url.replace("postgresql+asyncpg://", "postgresql+psycopg2://")
    return url


def render_item(type_, obj, autogen_context) -> str | bool:
    """Render pgvector's column type with the import it needs.

    Autogenerate writes `pgvector.sqlalchemy.Vector(dim=768)` for an embedding
    column and imports nothing, so a generated revision does not even import -
    every embedding column had to be fixed by hand. Adding the import to
    `autogen_context.imports` puts it in the file's `${imports}` block, and
    only in the revisions that actually have one.
    """
    if type_ == "type" and isinstance(obj, Vector):
        autogen_context.imports.add("import pgvector.sqlalchemy")
        return f"pgvector.sqlalchemy.Vector(dim={obj.dim})"
    return False


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode.

    This configures the context with just a URL
    and not an Engine, though an Engine is acceptable
    here as well.  By skipping the Engine creation
    we don't even need a DBAPI to be available.

    Calls to context.execute() here emit the given string to the
    script output.

    """
    context.configure(
        url=database_url(),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        render_item=render_item,
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode.

    In this scenario we need to create an Engine
    and associate a connection with the context.

    """
    # alembic.ini carries no URL (no credential in a tracked file), so the
    # engine below is configured from the settings instead.
    config.set_main_option("sqlalchemy.url", database_url())

    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata, render_item=render_item
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
