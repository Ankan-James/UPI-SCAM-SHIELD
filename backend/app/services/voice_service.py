"""Voice-related helpers for the backend."""

from __future__ import annotations


def build_voice_summary(risk_level: str, recommendation: str) -> str:
    return f"Risk level is {risk_level}. {recommendation}"
