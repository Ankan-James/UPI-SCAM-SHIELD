"""Risk-analysis endpoints."""

from __future__ import annotations

import json
import sqlite3

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from backend.app.database.connection import get_db
from backend.app.services.agent_service import AgentService

router = APIRouter()


class AnalyzeRequest(BaseModel):
    type: str = Field(default="text")
    input: str = Field(..., min_length=1)


@router.post("/analyze")
def analyze(payload: AnalyzeRequest, db: sqlite3.Connection = Depends(get_db)):
    if not payload.input or not payload.input.strip():
        raise HTTPException(status_code=400, detail="input is required")
    result = AgentService.analyze(payload.type, payload.input)
    db.execute(
        "INSERT INTO analysis_history (user_id, input_type, input_fingerprint, risk_score, risk_level, explanation, recommendation) VALUES (?, ?, ?, ?, ?, ?, ?)",
        (None, payload.type, payload.input[:64], result["score"], result["level"].lower(), json.dumps(result["indicators"]), result["recommendation"]),
    )
    return result
