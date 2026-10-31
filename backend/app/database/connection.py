"""SQLite connection helpers.

Every connection enables foreign-key enforcement (SQLite defaults to OFF).
Use `transaction()` for writes so a failure rolls everything back.
"""
import os
import sqlite3
from collections.abc import Iterator
from contextlib import contextmanager
from pathlib import Path

from sqlalchemy import create_engine, event
from sqlalchemy.engine import Engine, URL
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from backend.app.config import settings

REPO_ROOT = Path(__file__).resolve().parents[3]
SCHEMA_PATH = REPO_ROOT / "database" / "schema.sql"
USER_NAME_MIGRATION_PATH = REPO_ROOT / "database" / "migrations" / "001_add_user_name.sql"
DEFAULT_DB_PATH = Path(settings.database_path)


def get_db_path() -> Path:
    configured_path = Path(os.getenv("DATABASE_PATH", DEFAULT_DB_PATH)).expanduser()
    if not configured_path.is_absolute():
        configured_path = REPO_ROOT / configured_path
    return configured_path


def create_database_engine(database_path: str | Path | None = None) -> Engine:
    path = Path(database_path or settings.database_path).expanduser()
    is_memory_database = str(path) == ":memory:"
    if not is_memory_database:
        if not path.is_absolute():
            path = REPO_ROOT / path
        path.parent.mkdir(parents=True, exist_ok=True)

    connect_args = {"check_same_thread": False}
    engine_options = {}
    if is_memory_database:
        engine_options["poolclass"] = StaticPool

    database_url = URL.create(
        "sqlite",
        database=":memory:" if is_memory_database else str(path),
    )
    database_engine = create_engine(
        database_url,
        connect_args=connect_args,
        pool_pre_ping=True,
        **engine_options,
    )

    @event.listens_for(database_engine, "connect")
    def enable_foreign_keys(dbapi_connection, _connection_record) -> None:
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys = ON")
        cursor.close()

    return database_engine


engine = create_database_engine()
SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


def get_session() -> Iterator[Session]:
    """FastAPI dependency for SQLAlchemy-backed routes."""
    with SessionLocal() as session:
        yield session


def get_connection(db_path=None) -> sqlite3.Connection:
    path = Path(db_path) if db_path else get_db_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    # isolation_level=None -> we control BEGIN/COMMIT ourselves in transaction().
    conn = sqlite3.connect(path, isolation_level=None, timeout=10)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    conn.execute("PRAGMA journal_mode = WAL")
    return conn


@contextmanager
def transaction(db_path=None):
    """Yield a connection inside BEGIN/COMMIT; ROLLBACK on any exception."""
    conn = get_connection(db_path)
    try:
        conn.execute("BEGIN")
        yield conn
        conn.execute("COMMIT")
    except BaseException:
        conn.execute("ROLLBACK")
        raise
    finally:
        conn.close()


def init_db(db_path=None) -> None:
    """Create all tables/indexes from database/schema.sql (safe to re-run)."""
    conn = get_connection(db_path)
    try:
        conn.executescript(SCHEMA_PATH.read_text(encoding="utf-8"))
        user_columns = {
            row["name"] for row in conn.execute("PRAGMA table_info(users)").fetchall()
        }
        if "name" not in user_columns:
            conn.executescript(USER_NAME_MIGRATION_PATH.read_text(encoding="utf-8"))
    finally:
        conn.close()


def get_db() -> Iterator[sqlite3.Connection]:
    """FastAPI dependency: one connection per request (reads; use transaction() to write)."""
    conn = get_connection()
    try:
        yield conn
    finally:
        conn.close()
