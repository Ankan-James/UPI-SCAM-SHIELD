"""Explainable risk scoring that does not trust an LLM-supplied score."""

from __future__ import annotations

from collections.abc import Iterable
from typing import Any

from agent.config import Settings, get_settings


def _weight_for(category: str, settings: Settings) -> tuple[str, int]:
    normalized = category.upper()
    if normalized in {"DANGEROUS_CREDENTIAL_REQUEST", "OTP_FRAUD", "UPI_PIN_FRAUD"}:
        return "credential", settings.dangerous_credential_weight
    if normalized in {"SUSPICIOUS_URL", "PHISHING"}:
        return "url", settings.suspicious_url_weight
    if normalized in {"URGENCY_OR_THREAT", "SOCIAL_ENGINEERING"}:
        return "urgency", settings.urgency_weight
    if normalized in {"IMPERSONATION", "KYC_OR_IMPERSONATION"}:
        return "impersonation", settings.impersonation_weight
    if normalized in {
        "PAYMENT_MANIPULATION",
        "LOTTERY_FRAUD",
        "JOB_FRAUD",
        "REMOTE_ACCESS_SCAM",
        "SUSPICIOUS_QR",
    }:
        return "payment", settings.payment_manipulation_weight
    return normalized.lower(), 0


def score_findings(
    findings: Iterable[dict[str, Any]],
    *,
    settings: Settings | None = None,
) -> dict[str, Any]:
    """Score the strongest unique signal in each configured risk family."""
    active_settings = settings or get_settings()
    unique_findings = list(findings)
    strongest: dict[str, tuple[int, str]] = {}
    seen: set[tuple[str, str]] = set()
    explanations: list[str] = []
    for finding in unique_findings:
        if not isinstance(finding, dict):
            continue
        rule_id = str(finding.get("rule_id", ""))
        evidence = str(finding.get("evidence", ""))
        key = (rule_id, evidence)
        if not rule_id or key in seen:
            continue
        seen.add(key)
        family, weight = _weight_for(str(finding.get("category", "")), active_settings)
        try:
            severity = max(1, min(int(finding.get("severity", 1)), 5))
        except (TypeError, ValueError):
            continue
        contribution = round(weight * severity / 5)
        current = strongest.get(family, (0, ""))
        if contribution > current[0]:
            strongest[family] = (contribution, str(finding.get("explanation", evidence)))
    score = min(100, sum(value for value, _ in strongest.values()))
    if score <= active_settings.low_risk_max:
        level = "LOW"
    elif score <= active_settings.medium_risk_max:
        level = "MEDIUM"
    else:
        level = "HIGH"
    explanations = [text for value, text in strongest.values() if value and text]
    return {
        "score": score,
        "level": level,
        "explanation": " ".join(dict.fromkeys(explanations))
        or "No deterministic risk indicators were detected; this does not guarantee safety.",
        "contributions": {key: value for key, (value, _) in strongest.items() if value},
        "indicators": list(dict.fromkeys(
            str(item.get("evidence", "")) for item in unique_findings
            if isinstance(item, dict) and item.get("evidence")
        )),
    }


def calculate_risk(
    score: int | Iterable[dict[str, Any]],
    indicators: list[str] | None = None,
    *,
    source: str = "unknown",
) -> dict[str, Any]:
    """Compatibility scoring interface for the existing backend adapter."""
    if isinstance(score, int):
        final_score = max(0, min(score, 100))
        findings: list[str] = indicators or []
        result = {"score": final_score, "indicators": sorted(set(findings))}
        result["level"] = (
            "HIGH" if final_score > get_settings().medium_risk_max else
            "MEDIUM" if final_score > get_settings().low_risk_max else "LOW"
        )
        result["recommendation"] = (
            "Pause; do not share credentials or pay, and verify independently."
            if result["level"] == "HIGH" else
            "Pause and verify the sender, recipient, or link independently."
            if result["level"] == "MEDIUM" else
            "No obvious warning signs were detected; remain cautious."
        )
        result["source"] = source
        return result
    scored = score_findings(score)
    return {
        **scored,
        "recommendation": (
            "Pause; do not share credentials or pay, and verify independently."
            if scored["level"] == "HIGH" else
            "Pause and verify the sender, recipient, or link independently."
            if scored["level"] == "MEDIUM" else
            "No obvious warning signs were detected; remain cautious."
        ),
        "source": source,
    }
