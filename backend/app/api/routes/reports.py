"""Report submission endpoints."""

from __future__ import annotations

import sqlite3

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from backend.app.database.connection import get_db

router = APIRouter()


class ReportRequest(BaseModel):
    report_type: str = Field(default="other")
    description: str = Field(..., min_length=1, max_length=2000)


@router.post("/reports")
def create_report(payload: ReportRequest, db: sqlite3.Connection = Depends(get_db)):
    row = db.execute(
        "INSERT INTO reports (user_id, report_type, description, status) VALUES (?, ?, ?, 'submitted')",
        (None, payload.report_type, payload.description),
    )
    return {"id": row.lastrowid, "status": "Pending Review"}
