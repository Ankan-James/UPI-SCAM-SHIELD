"""Security lock endpoints."""

from __future__ import annotations

from fastapi import APIRouter

router = APIRouter()


@router.post("/security/lock")
def lock_account():
    return {"locked": True}


@router.post("/security/unlock")
def unlock_account():
    return {"locked": False}
