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

    @property
    def allowed_frontend_origins(self) -> list[str]:
        origins = {"http://127.0.0.1:5501", "http://localhost:5501"}
        if self.frontend_origin != "*":
            origins.update(
                origin.strip()
                for origin in self.frontend_origin.split(",")
                if origin.strip()
            )
        return sorted(origins)


settings = Settings()
