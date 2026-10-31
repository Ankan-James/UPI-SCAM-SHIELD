"""Deterministic analysis of suspicious message content."""

from __future__ import annotations

from typing import Any

from .scam_patterns import detect_patterns


def analyze_text_message(value: str) -> dict[str, Any]:
    """Analyze text with contextual deterministic rules."""
    findings = detect_patterns(value)
    if "http" in value.lower() or "www." in value.lower():
        from .url_analyzer import analyze_url
        from agent.processing.text_processor import process_text

        for url in process_text(value).urls:
            result = analyze_url(url)
            findings.extend(result["findings"])
    unique = {item["rule_id"]: item for item in findings}
    findings = list(unique.values())
    score = min(
        100,
        sum({"DANGEROUS_CREDENTIAL_REQUEST": 30, "URGENCY_OR_THREAT": 15,
             "KYC_OR_IMPERSONATION": 15, "PAYMENT_MANIPULATION": 15,
             "IMPERSONATION": 15, "REMOTE_ACCESS_SCAM": 30,
             "SUSPICIOUS_URL": 25}.get(item["category"], 0) for item in findings),
    )
    return {
        "score": score,
        "indicators": [item["evidence"] for item in findings],
        "risk_level": "HIGH" if score >= 70 else "MEDIUM" if score >= 30 else "LOW",
        "findings": findings,
    }
