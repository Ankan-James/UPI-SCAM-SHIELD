"""Authentication endpoints."""

from __future__ import annotations

import sqlite3
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel, Field

from backend.app.database.connection import get_db
from backend.app.security.sessions import hash_token, is_session_valid, parse_bearer_token
from backend.app.services.auth_service import AuthService

router = APIRouter()


class RegisterRequest(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    username: str | None = Field(default=None, min_length=3, max_length=50)
    email: str = Field(..., min_length=3, max_length=254)
    password: str = Field(..., min_length=8, max_length=256)


class LoginRequest(BaseModel):
    email: str = Field(..., min_length=3, max_length=254)
    password: str = Field(..., min_length=1, max_length=256)


@router.post("/auth/register")
def register(payload: RegisterRequest, db: sqlite3.Connection = Depends(get_db)):
    if not payload.name and not payload.username:
        raise HTTPException(status_code=422, detail="name is required")
    try:
        user = AuthService.register_user(
            db,
            payload.username,
            payload.email,
            payload.password,
            name=payload.name,
        )
        return {"success": True, "user": user}
    except ValueError as exc:
        status_code = 409 if "already exists" in str(exc) else 400
        raise HTTPException(status_code=status_code, detail=str(exc)) from exc


@router.post("/auth/login")
def login(payload: LoginRequest, db: sqlite3.Connection = Depends(get_db)):
    try:
        user_id, token = AuthService.login_user(db, payload.email, payload.password)
        user = AuthService.get_user(db, user_id)
        if user is None:
            raise HTTPException(status_code=401, detail="invalid email or password")
        return {"success": True, "token": token, "user": user, "user_id": user_id}
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc)) from exc


@router.get("/auth/me")
def me(authorization: str | None = Header(default=None, alias="Authorization"), db: sqlite3.Connection = Depends(get_db)):
    token = parse_bearer_token(authorization)
    if not token:
        raise HTTPException(status_code=401, detail="missing bearer token")
    token_hash = hash_token(token)
    row = db.execute(
        "SELECT user_id, expires_at, revoked_at FROM sessions WHERE token_hash = ?",
        (token_hash,),
    ).fetchone()
    if not row or not is_session_valid(row["expires_at"], row["revoked_at"]):
        raise HTTPException(status_code=401, detail="invalid or expired token")
    user = AuthService.get_user(db, row["user_id"])
    return {"success": True, "user": user}


@router.post("/auth/logout")
def logout(authorization: str | None = Header(default=None, alias="Authorization"), db: sqlite3.Connection = Depends(get_db)):
    token = parse_bearer_token(authorization)
    if not token:
        raise HTTPException(status_code=401, detail="missing bearer token")
    token_hash = hash_token(token)
    row = db.execute(
        "SELECT user_id, expires_at, revoked_at FROM sessions WHERE token_hash = ?",
        (token_hash,),
    ).fetchone()
    if not row:
        return {"success": True, "message": "already logged out"}
    if not is_session_valid(row["expires_at"], row["revoked_at"]):
        db.execute(
            "UPDATE sessions SET revoked_at = ? WHERE token_hash = ?",
            (datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"), token_hash),
        )
        return {"success": True, "message": "already logged out"}
    AuthService.logout_user(db, row["user_id"], token)
    return {"success": True, "message": "logged out"}
