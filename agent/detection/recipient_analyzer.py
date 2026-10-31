"""Evidence-based analysis of caller-supplied recipient reputation data."""

from __future__ import annotations

import re
from typing import Any

_UPI_ID = re.compile(r"(?i)^[a-z0-9._-]{2,256}@[a-z][a-z0-9.-]{1,63}$")
_STATES = {
    "TRUSTED_DATA_AVAILABLE",
    "SUSPICIOUS_REPORTED",
    "VALIDATED_RISK_INDICATORS",
    "UNKNOWN",
}


def analyze_recipient(
    recipient_id: str,
    reputation: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Validate an identifier and interpret only supplied reputation evidence."""
    normalized = (recipient_id or "").strip().lower()
    if not _UPI_ID.fullmatch(normalized):
        raise ValueError("Recipient must be a syntactically valid UPI ID")
    if reputation is not None and not isinstance(reputation, dict):
        raise ValueError("Reputation data must be an object")
    supplied = reputation or {}
    state = str(supplied.get("state", "UNKNOWN")).upper()
    if state not in _STATES:
        raise ValueError(f"Unsupported reputation state: {state}")
    reports = supplied.get("reports", [])
    if not isinstance(reports, list):
        raise ValueError("Reputation reports must be a list")
    findings: list[dict[str, Any]] = []
    if state == "VALIDATED_RISK_INDICATORS":
        findings.append(
            {
                "rule_id": "recipient.validated_risk",
                "category": "PAYMENT_MANIPULATION",
                "evidence": "External reputation data reports validated risk indicators.",
                "severity": 4,
                "explanation": "Supplied reputation data includes validated risk indicators; verify its source and freshness.",
                "source": "external_reputation",
            }
        )
    elif state == "SUSPICIOUS_REPORTED":
        verified = [item for item in reports if isinstance(item, dict) and item.get("verified") is True]
        unverified = [item for item in reports if isinstance(item, dict) and item.get("verified") is not True]
        if verified:
            findings.append(
                {
                    "rule_id": "recipient.verified_reports",
                    "category": "PAYMENT_MANIPULATION",
                    "evidence": f"{len(verified)} verified report(s) supplied by the caller.",
                    "severity": min(4, 2 + len(verified)),
                    "explanation": "Caller-supplied verified reports warrant independent verification; they do not prove wrongdoing.",
                    "source": "external_reputation",
                }
            )
        if unverified:
            findings.append(
                {
                    "rule_id": "recipient.unverified_reports",
                    "category": "UNVERIFIED_REPORT",
                    "evidence": f"{len(unverified)} unverified report(s) supplied by the caller.",
                    "severity": 1,
                    "explanation": "Unverified reports are weak claims and are not treated as proof of fraud.",
                    "source": "external_reputation",
                }
            )
    return {
        "recipient_id": normalized,
        "state": state,
        "findings": findings,
        "limitations": [
            "Reputation status is caller-supplied and may be incomplete or stale.",
            "Unknown or trusted-data states do not guarantee recipient safety.",
        ],
    }
