"""Password helpers."""

from __future__ import annotations

import bcrypt
from argon2.exceptions import InvalidHashError, VerificationError
from passlib.context import CryptContext

legacy_pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")
BCRYPT_ROUNDS = 12


def hash_password(password: str) -> str:
    password_bytes = password.encode("utf-8")
    if len(password_bytes) > 72:
        raise ValueError("password must be at most 72 UTF-8 bytes")
    return bcrypt.hashpw(
        password_bytes,
        bcrypt.gensalt(rounds=BCRYPT_ROUNDS),
    ).decode("ascii")


def verify_password(password: str, password_hash: str) -> bool:
    if password_hash.startswith("$argon2"):
        try:
            return legacy_pwd_context.verify(password, password_hash)
        except (InvalidHashError, VerificationError, ValueError, TypeError):
            return False

    if not password_hash.startswith(("$2a$", "$2b$", "$2y$")):
        return False

    try:
        return bcrypt.checkpw(password.encode("utf-8"), password_hash.encode("ascii"))
    except (ValueError, TypeError, UnicodeEncodeError):
        return False
