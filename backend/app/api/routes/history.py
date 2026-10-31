"""History endpoints for prior analyses and account activity."""

from __future__ import annotations

import sqlite3

from fastapi import APIRouter, Depends

from backend.app.database.connection import get_db

router = APIRouter()


@router.get("/history")
def history(db: sqlite3.Connection = Depends(get_db)):
    rows = db.execute(
        "SELECT analysis_id, input_type, risk_score, risk_level, created_at FROM analysis_history ORDER BY created_at DESC LIMIT 20"
    ).fetchall()
    return {"items": [dict(row) for row in rows]}
