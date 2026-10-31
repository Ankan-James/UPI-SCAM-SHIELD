"""Voice-related endpoints."""

from __future__ import annotations

from fastapi import APIRouter

from backend.app.services.voice_service import build_voice_summary

router = APIRouter()


@router.post("/voice/summary")
def voice_summary(payload: dict):
    risk_level = payload.get("risk_level", "low")
    recommendation = payload.get("recommendation", "Verify the source before continuing.")
    return {"summary": build_voice_summary(risk_level, recommendation)}
