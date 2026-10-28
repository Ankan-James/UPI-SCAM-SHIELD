"""SQLite connection helpers.

Every connection enables foreign-key enforcement (SQLite defaults to OFF).
Use `transaction()` for writes so a failure rolls everything back.
"""
import os
import sqlite3
from contextlib import contextmanager
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
SCHEMA_PATH = REPO_ROOT / "database" / "schema.sql"
DEFAULT_DB_PATH = REPO_ROOT / "backend" / "data" / "scam_shield.db"  # git-ignored


def get_db_path() -> Path:
    return Path(os.getenv("DATABASE_PATH", DEFAULT_DB_PATH))


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
    finally:
        conn.close()


def get_db():
    """FastAPI dependency: one connection per request (reads; use transaction() to write)."""
    conn = get_connection()
    try:
        yield conn
    finally:
        conn.close()
