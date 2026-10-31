"""Initialize the canonical SQLite schema for new databases."""

from __future__ import annotations

import sqlite3
from pathlib import Path

from alembic import op
import sqlalchemy as sa

revision = "0001_bootstrap_schema"
down_revision = None
branch_labels = None
depends_on = None

SCHEMA_PATH = Path(__file__).resolve().parents[3] / "database" / "schema.sql"


def upgrade() -> None:
    connection = op.get_bind()
    if connection.dialect.name != "sqlite":
        raise RuntimeError("The bootstrap migration currently supports SQLite only")

    pending = ""
    for line in SCHEMA_PATH.read_text(encoding="utf-8").splitlines(keepends=True):
        pending += line
        if sqlite3.complete_statement(pending):
            statement = pending.strip()
            pending = ""
            if statement:
                connection.exec_driver_sql(statement)
    if pending.strip():
        raise RuntimeError("The canonical SQLite schema contains an incomplete statement")

    user_columns = {
        row[1]
        for row in connection.exec_driver_sql("PRAGMA table_info(users)").fetchall()
    }
    if "name" not in user_columns:
        op.add_column(
            "users",
            sa.Column("name", sa.String(length=100), nullable=False, server_default=""),
        )
        op.execute(sa.text("UPDATE users SET name = username WHERE name = ''"))


def downgrade() -> None:
    # This migration establishes the initial schema and is intentionally irreversible.
    pass
