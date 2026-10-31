"""Payment endpoints."""

from __future__ import annotations

import sqlite3

from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel, Field

from backend.app.database.connection import get_db
from backend.app.security.sessions import hash_token, is_session_valid, parse_bearer_token
from backend.app.services.agent_service import AgentService

router = APIRouter()


class SendPaymentRequest(BaseModel):
    recipient: str = Field(..., min_length=1)
    amount: int = Field(..., gt=0)
    note: str | None = None


@router.post("/payments/send")
def send_payment(
    payload: SendPaymentRequest,
    authorization: str | None = Header(default=None, alias="Authorization"),
    db: sqlite3.Connection = Depends(get_db),
):
    token = parse_bearer_token(authorization)
    if not token:
        raise HTTPException(status_code=401, detail="missing bearer token")

    token_hash = hash_token(token)
    session = db.execute(
        "SELECT user_id, expires_at, revoked_at FROM sessions WHERE token_hash = ?",
        (token_hash,),
    ).fetchone()
    if not session or not is_session_valid(session["expires_at"], session["revoked_at"]):
        raise HTTPException(status_code=401, detail="invalid or expired token")

    result = AgentService.analyze("upi_id", payload.recipient)
    if result["score"] >= 70:
        raise HTTPException(status_code=400, detail="Payment blocked due to scam risk")

    sender_user_id = session["user_id"]
    sender_account = db.execute(
        "SELECT balance_in_paise FROM accounts WHERE user_id = ?",
        (sender_user_id,),
    ).fetchone()
    if not sender_account:
        raise HTTPException(status_code=404, detail="account not found")
    if sender_account["balance_in_paise"] < payload.amount:
        raise HTTPException(status_code=400, detail="insufficient balance")

    receiver = db.execute(
        "SELECT user_id, upi_id FROM accounts WHERE upi_id = ?",
        (payload.recipient.strip(),),
    ).fetchone()

    try:
        db.execute("BEGIN")
        db.execute(
            "UPDATE accounts SET balance_in_paise = balance_in_paise - ? WHERE user_id = ?",
            (payload.amount, sender_user_id),
        )
        receiver_user_id = receiver["user_id"] if receiver else None
        if receiver_user_id and receiver_user_id != sender_user_id:
            db.execute(
                "UPDATE accounts SET balance_in_paise = balance_in_paise + ? WHERE user_id = ?",
                (payload.amount, receiver_user_id),
            )
        transaction_row = db.execute(
            "INSERT INTO transactions (sender_user_id, receiver_user_id, amount_in_paise, currency, status, note) VALUES (?, ?, ?, 'INR', 'success', ?)",
            (sender_user_id, receiver_user_id, payload.amount, payload.note or "simulated payment"),
        )
        db.execute(
            "INSERT INTO activity_logs (user_id, platform, event_type, page_name) VALUES (?, ?, ?, ?)",
            (sender_user_id, "android", "payment_sent", "send"),
        )
        db.execute("COMMIT")
    except Exception:
        db.execute("ROLLBACK")
        raise

    return {
        "success": True,
        "transaction_id": f"TXN{transaction_row.lastrowid:09d}",
        "amount": payload.amount,
        "currency": "INR",
        "status": "success",
        "message": "Payment completed successfully",
    }
