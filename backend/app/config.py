"""Application settings used by the backend."""

from __future__ import annotations

import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
REPO_ROOT = BASE_DIR.parent

class Settings:
    app_name: str = "UPI Scam Shield API"
    database_path: str = os.getenv("DATABASE_PATH", str(BASE_DIR / "data" / "scam_shield.db"))
    secret_key: str = os.getenv("SECRET_KEY", "change-me-in-production")
    access_token_expire_minutes: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))
    frontend_origin: str = os.getenv("FRONTEND_ORIGIN", "*")

settings = Settings()

