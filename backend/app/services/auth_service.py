"""Authentication service for registration, login, and session creation."""

from __future__ import annotations

import sqlite3
import re
import unicodedata
from datetime import datetime, timedelta, timezone

from backend.app.database.connection import get_connection
from backend.app.security.password import hash_password, verify_password
from backend.app.security.sessions import expires_at, hash_token, make_token


class AuthService:
    @staticmethod
    def register_user(
        db: sqlite3.Connection,
        username: str | None,
        email: str,
        password: str,
        *,
        name: str | None = None,
    ) -> dict:
        display_name = (name or username or "").strip()
        normalized_username = (username or "").strip()
        normalized_email = (email or "").strip().lower()
        if not display_name or not normalized_email or not password:
            raise ValueError("name, email, and password are required")
        if len(display_name) > 100:
            raise ValueError("name must be at most 100 characters")
        if username and len(normalized_username) < 3:
            raise ValueError("username must be at least 3 characters")
        if not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", normalized_email) or len(normalized_email) > 254:
            raise ValueError("enter a valid email address")
        if len(password) < 8:
            raise ValueError("password must be at least 8 characters")
        if len(password.encode("utf-8")) > 72:
            raise ValueError("password must be at most 72 UTF-8 bytes")

        password_hash = hash_password(password)
        db.execute("SAVEPOINT register_user")
        try:
            existing_email = db.execute(
                "SELECT user_id FROM users WHERE email = ?",
                (normalized_email,),
            ).fetchone()
            if existing_email:
                raise ValueError("an account with that email already exists")

            if normalized_username:
                existing_username = db.execute(
                    "SELECT user_id FROM users WHERE username = ?",
                    (normalized_username,),
                ).fetchone()
                if existing_username:
                    raise ValueError("a user with that username already exists")
            else:
                ascii_name = unicodedata.normalize("NFKD", display_name).encode("ascii", "ignore").decode("ascii")
                username_base = re.sub(r"[^a-z0-9._-]", "", ascii_name.lower())[:40] or "numpe-user"
                normalized_username = username_base
                suffix = 2
                while db.execute(
                    "SELECT 1 FROM users WHERE username = ?",
                    (normalized_username,),
                ).fetchone():
                    normalized_username = f"{username_base[:47]}-{suffix}"
                    suffix += 1

            row = db.execute(
                "INSERT INTO users (username, name, email, password_hash) VALUES (?, ?, ?, ?)",
                (normalized_username, display_name, normalized_email, password_hash),
            )
            user_id = row.lastrowid
            account_number = f"NUMPE{user_id:09d}"
            upi_id = f"{normalized_username.lower()}@numpe"
            db.execute(
                "INSERT INTO accounts (user_id, account_number, upi_id, balance_in_paise) VALUES (?, ?, ?, ?)",
                (user_id, account_number, upi_id, 1000000),
            )
            db.execute("RELEASE SAVEPOINT register_user")
        except BaseException:
            db.execute("ROLLBACK TO SAVEPOINT register_user")
            db.execute("RELEASE SAVEPOINT register_user")
            raise

        return {
            "id": user_id,
            "user_id": user_id,
            "name": display_name,
            "username": normalized_username,
            "email": normalized_email,
            "upi_id": upi_id,
        }

    @staticmethod
    def login_user(db: sqlite3.Connection, email: str, password: str) -> tuple[int, str]:
        email = (email or "").strip().lower()
        row = db.execute("SELECT user_id, password_hash, username FROM users WHERE email = ?", (email,)).fetchone()
        if not row or not verify_password(password, row["password_hash"]):
            raise ValueError("invalid email or password")
        token = make_token()
        token_hash = hash_token(token)
        expires = datetime.now(timezone.utc) + timedelta(minutes=60)
        db.execute(
            "INSERT INTO sessions (user_id, token_hash, expires_at) VALUES (?, ?, ?)",
            (row["user_id"], token_hash, expires.strftime("%Y-%m-%dT%H:%M:%SZ")),
        )
        return row["user_id"], token

    @staticmethod
    def logout_user(db: sqlite3.Connection, user_id: int, token: str) -> bool:
        token_hash = hash_token(token)
        db.execute(
            "UPDATE sessions SET revoked_at = ? WHERE user_id = ? AND token_hash = ? AND revoked_at IS NULL",
            (datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"), user_id, token_hash),
        )
        return True

    @staticmethod
    def get_user(db: sqlite3.Connection, user_id: int) -> dict | None:
        row = db.execute(
            "SELECT user_id, username, name, email, created_at FROM users WHERE user_id = ?",
            (user_id,),
        ).fetchone()
        if not row:
            return None
        account = db.execute(
            "SELECT account_number, upi_id, balance_in_paise FROM accounts WHERE user_id = ?",
            (user_id,),
        ).fetchone()
        payload = {
            "id": row["user_id"],
            "user_id": row["user_id"],
            "name": row["name"],
            "username": row["username"],
            "email": row["email"],
            "created_at": row["created_at"],
        }
        if account:
            payload["account_number"] = account["account_number"]
            payload["upi_id"] = account["upi_id"]
            payload["balance_in_paise"] = account["balance_in_paise"]
        return payload
