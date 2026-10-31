"""Authentication endpoints."""

from __future__ import annotations

import sqlite3

from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel, Field

from backend.app.database.connection import get_db
from backend.app.security.sessions import hash_token, parse_bearer_token
from backend.app.services.auth_service import AuthService

router = APIRouter()


class RegisterRequest(BaseModel):
    username: str = Field(..., min_length=3)
    email: str = Field(..., min_length=3)
    password: str = Field(..., min_length=6)


class LoginRequest(BaseModel):
    email: str = Field(..., min_length=3)
    password: str = Field(..., min_length=6)


@router.post("/auth/register")
def register(payload: RegisterRequest, db: sqlite3.Connection = Depends(get_db)):
    try:
        user = AuthService.register_user(db, payload.username, payload.email, payload.password)
        return {"success": True, "user": user}
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.post("/auth/login")
def login(payload: LoginRequest, db: sqlite3.Connection = Depends(get_db)):
    try:
        user_id, token = AuthService.login_user(db, payload.email, payload.password)
        return {"success": True, "token": token, "user_id": user_id}
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc)) from exc


@router.get("/auth/me")
def me(authorization: str | None = Header(default=None, alias="Authorization"), db: sqlite3.Connection = Depends(get_db)):
    token = parse_bearer_token(authorization)
    if not token:
        raise HTTPException(status_code=401, detail="missing bearer token")
    token_hash = hash_token(token)
    row = db.execute("SELECT user_id FROM sessions WHERE token_hash = ? AND revoked_at IS NULL", (token_hash,)).fetchone()
    if not row:
        raise HTTPException(status_code=401, detail="invalid or expired token")
    user = AuthService.get_user(db, row["user_id"])
    return {"success": True, "user": user}


@router.post("/auth/logout")
def logout(authorization: str | None = Header(default=None, alias="Authorization"), db: sqlite3.Connection = Depends(get_db)):
    token = parse_bearer_token(authorization)
    if not token:
        raise HTTPException(status_code=401, detail="missing bearer token")
    token_hash = hash_token(token)
    row = db.execute("SELECT user_id FROM sessions WHERE token_hash = ? AND revoked_at IS NULL", (token_hash,)).fetchone()
    if not row:
        return {"success": True, "message": "already logged out"}
    AuthService.logout_user(db, row["user_id"], token)
    return {"success": True, "message": "logged out"}
