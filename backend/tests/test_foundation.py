from __future__ import annotations

import sqlite3
from pathlib import Path

import pytest
from alembic import command
from alembic.config import Config
from fastapi.testclient import TestClient
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

from backend.app.config import settings
from backend.app.database.connection import create_database_engine, get_connection, transaction
from backend.app.main import app


def test_sqlalchemy_engine_enforces_foreign_keys(tmp_path: Path) -> None:
    database_engine = create_database_engine(tmp_path / "constraints.sqlite")
    try:
        with (
            database_engine.connect() as first_connection,
            database_engine.connect() as second_connection,
        ):
            assert first_connection.execute(text("PRAGMA foreign_keys")).scalar() == 1
            assert second_connection.execute(text("PRAGMA foreign_keys")).scalar() == 1
            first_connection.execute(
                text("CREATE TABLE parent (id INTEGER PRIMARY KEY)")
            )
            first_connection.execute(
                text(
                    "CREATE TABLE child (parent_id INTEGER REFERENCES parent(id))"
                )
            )
            first_connection.commit()

        with pytest.raises(IntegrityError):
            with database_engine.begin() as connection:
                connection.execute(text("INSERT INTO child (parent_id) VALUES (9)"))
    finally:
        database_engine.dispose()


def test_legacy_connection_enables_foreign_keys(tmp_path: Path) -> None:
    connection = get_connection(tmp_path / "legacy.sqlite")
    try:
        assert connection.execute("PRAGMA foreign_keys").fetchone()[0] == 1
    finally:
        connection.close()


def test_transaction_rolls_back_after_failure(tmp_path: Path) -> None:
    database_path = tmp_path / "rollback.sqlite"
    with pytest.raises(RuntimeError):
        with transaction(database_path) as connection:
            connection.execute("CREATE TABLE rollback_check (id INTEGER)")
            raise RuntimeError("force rollback")

    connection = sqlite3.connect(database_path)
    try:
        table = connection.execute(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'rollback_check'"
        ).fetchone()
    finally:
        connection.close()
    assert table is None


def test_alembic_bootstrap_creates_canonical_schema(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    database_path = tmp_path / "migration.sqlite"
    monkeypatch.setattr(settings, "database_path", str(database_path))
    project_root = Path(__file__).resolve().parents[2]
    alembic_config = Config(str(project_root / "alembic.ini"))

    command.upgrade(alembic_config, "head")

    connection = sqlite3.connect(database_path)
    try:
        tables = {
            row[0]
            for row in connection.execute(
                "SELECT name FROM sqlite_master WHERE type = 'table'"
            )
        }
        user_columns = {
            row[1] for row in connection.execute("PRAGMA table_info(users)")
        }
    finally:
        connection.close()
    assert {"users", "sessions", "accounts", "transactions"} <= tables
    assert "name" in user_columns


def test_health_endpoint_initializes_and_checks_database() -> None:
    with TestClient(app) as client:
        response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
