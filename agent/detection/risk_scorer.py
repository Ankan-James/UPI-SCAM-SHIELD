"""Combine detection evidence into a final risk score."""

from __future__ import annotations


def calculate_risk(score: int, indicators: list[str] | None = None, *, source: str = 'unknown') -> dict:
    data = {"score": max(0, min(int(score), 100)), "level": "low"}
    if data["score"] >= 80:
        data["level"] = "high"
    elif data["score"] >= 40:
        data["level"] = "medium"
    if indicators:
        data["indicators"] = sorted(set(indicators))
    else:
        data["indicators"] = []
    data["recommendation"] = (
        "Pause and verify independently before taking any action."
        if data["level"] == "high"
        else "Proceed with caution and double-check the sender or link."
        if data["level"] == "medium"
        else "No obvious warning signs detected; stay cautious."
    )
    data["source"] = source
    return data
