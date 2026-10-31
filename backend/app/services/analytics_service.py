"""Utilities for recording activity and retrieving summaries."""

from __future__ import annotations

import sqlite3
from datetime import datetime, timezone


class AnalyticsService:
    @staticmethod
    def log_event(db: sqlite3.Connection, user_id: int | None, platform: str, event_type: str, page_name: str | None = None) -> None:
        db.execute(
            "INSERT INTO activity_logs (user_id, platform, event_type, page_name, created_at) VALUES (?, ?, ?, ?, ?)",
            (user_id, platform, event_type, page_name, datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")),
        )

    @staticmethod
    def get_summary(db: sqlite3.Connection) -> dict:
        total = db.execute("SELECT COUNT(*) AS value FROM activity_logs").fetchone()["value"]
        analyses = db.execute("SELECT COUNT(*) AS value FROM analysis_history").fetchone()["value"]
        returns = db.execute("SELECT COUNT(*) AS value FROM reports").fetchone()["value"]
        return {"total_events": total, "total_analyses": analyses, "total_reports": returns}
