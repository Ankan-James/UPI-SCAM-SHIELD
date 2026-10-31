"""Environment-backed application settings."""

from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parents[2]
REPO_ROOT = BASE_DIR.parent

load_dotenv(BASE_DIR / ".env")
load_dotenv(REPO_ROOT / ".env")


def _database_path() -> str:
    configured_path = Path(
        os.getenv("DATABASE_PATH", str(BASE_DIR / "data" / "scam_shield.db"))
    ).expanduser()
    if not configured_path.is_absolute():
        configured_path = REPO_ROOT / configured_path
    return str(configured_path)


class Settings:
    app_name: str = os.getenv("APP_NAME", "UPI Scam Shield API")
    database_path: str = _database_path()
    secret_key: str | None = os.getenv("SECRET_KEY")
    access_token_expire_minutes: int = int(
        os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60")
    )
    frontend_origin: str = os.getenv("FRONTEND_ORIGIN", "")

    @property
    def allowed_frontend_origins(self) -> list[str]:
        origins = {
            "http://127.0.0.1:5501",
            "http://localhost:5501",
            "http://127.0.0.1:5173",
            "http://localhost:5173",
            "http://127.0.0.1:5500",
            "http://localhost:5500",
            "http://127.0.0.1:3000",
            "http://localhost:3000",
        }
        origins.update(
            origin.strip()
            for origin in self.frontend_origin.split(",")
            if origin.strip()
        )
        return sorted(origins)


settings = Settings()
