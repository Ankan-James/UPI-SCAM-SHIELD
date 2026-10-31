from __future__ import annotations

from logging.config import fileConfig

from alembic import context
from sqlalchemy.engine import Connection, URL

from backend.app.config import settings
from backend.app.database.connection import create_database_engine

config = context.config
config.set_main_option(
    "sqlalchemy.url",
    URL.create("sqlite", database=settings.database_path)
    .render_as_string(hide_password=False)
    .replace("%", "%%"),
)

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# ORM declarations are still being aligned with the canonical SQLite schema.
target_metadata = None


def run_migrations_offline() -> None:
    context.configure(
        url=config.get_main_option("sqlalchemy.url"),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    connectable = create_database_engine(settings.database_path)
    try:
        with connectable.connect() as connection:
            _run_with_connection(connection)
    finally:
        connectable.dispose()


def _run_with_connection(connection: Connection) -> None:
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
