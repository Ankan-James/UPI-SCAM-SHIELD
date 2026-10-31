"""Payment endpoints."""

from __future__ import annotations

import sqlite3

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from backend.app.database.connection import get_db
from backend.app.services.agent_service import AgentService

router = APIRouter()


class SendPaymentRequest(BaseModel):
    recipient: str = Field(..., min_length=1)
    amount: float = Field(..., gt=0)
    note: str | None = None


@router.post("/payments/send")
def send_payment(payload: SendPaymentRequest, db: sqlite3.Connection = Depends(get_db)):
    result = AgentService.analyze("upi_id", payload.recipient)
    if result["score"] >= 70:
        raise HTTPException(status_code=400, detail="Payment blocked due to scam risk")
    db.execute(
        "INSERT INTO activity_logs (user_id, platform, event_type, page_name) VALUES (?, ?, ?, ?)",
        (None, "android", "payment_sent", "send"),
    )
    return {"id": f"NP{abs(hash(payload.recipient + str(payload.amount))) % 10**9:09d}", "status": "success"}
