"""High-level risk analysis entry point."""

from __future__ import annotations

from .detection.risk_scorer import calculate_risk
from .detection.text_analyzer import analyze_text_message
from .detection.url_analyzer import analyze_url


def analyze_input(input_type: str, value: str) -> dict:
    normalized_type = (input_type or "text").strip().lower()
    audit = {"type": normalized_type, "input": (value or "")[:500]}

    if normalized_type in {"text", "upi_id", "qr", "image"}:
        findings = analyze_text_message(value or "")
    elif normalized_type == "url":
        findings = analyze_url(value or "")
    else:
        findings = analyze_text_message(value or "")

    risk = calculate_risk(findings["score"], findings["indicators"], source=normalized_type)
    risk.update({"type": normalized_type, "analysis": findings})
    audit.update(risk)
    return audit
