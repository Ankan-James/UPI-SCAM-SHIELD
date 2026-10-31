"""Evidence-based financial scam pattern rules."""

from __future__ import annotations

import re
from typing import Any


_RULES: tuple[tuple[str, str, int, str, re.Pattern[str]], ...] = (
    (
        "credential.otp.request",
        "DANGEROUS_CREDENTIAL_REQUEST",
        5,
        "Requests a one-time password, which should not be shared with another person.",
        re.compile(
            r"\b(?:share|send|tell|provide|enter|verify|confirm|forward|reveal)\b"
            r".{0,45}\b(?:otp|one[- ]time password|security code)\b"
            r"|\b(?:otp|one[- ]time password|security code)\b"
            r".{0,45}\b(?:share|send|tell|provide|enter|verify|confirm|forward|reveal)\b",
            re.I,
        ),
    ),
    (
        "credential.upi_pin.request",
        "DANGEROUS_CREDENTIAL_REQUEST",
        5,
        "Requests a UPI PIN or asks the recipient to enter it outside a trusted payment flow.",
        re.compile(
            r"\b(?:share|send|tell|provide|enter|reveal)\b.{0,45}\b(?:upi\s*)?pin\b"
            r"|\b(?:upi\s*)?pin\b.{0,45}\b(?:share|send|tell|provide|enter|reveal)\b",
            re.I,
        ),
    ),
    (
        "credential.password.request",
        "DANGEROUS_CREDENTIAL_REQUEST",
        5,
        "Requests a password or account credential.",
        re.compile(
            r"\b(?:share|send|tell|provide|enter|reveal)\b.{0,45}\b(?:password|passcode)\b"
            r"|\b(?:password|passcode)\b.{0,45}\b(?:share|send|tell|provide|enter|reveal)\b",
            re.I,
        ),
    ),
    (
        "threat.account.suspension",
        "URGENCY_OR_THREAT",
        4,
        "Uses an account-blocking or suspension threat to pressure the recipient.",
        re.compile(
            r"\b(?:account|bank\s+account|upi)\b.{0,60}\b(?:block(?:ed)?|suspend(?:ed)?|deactivat(?:e|ed))\b"
            r"|\b(?:block(?:ed)?|suspend(?:ed)?|deactivat(?:e|ed))\b.{0,60}\b(?:account|bank|upi)\b",
            re.I,
        ),
    ),
    (
        "kyc.urgent.update",
        "KYC_OR_IMPERSONATION",
        3,
        "Combines an account-verification or KYC request with an instruction to act.",
        re.compile(
            r"\b(?:update|complete|verify|submit|renew)\b.{0,35}\b(?:kyc|account verification)\b"
            r"|\b(?:kyc|account verification)\b.{0,35}\b(?:update|complete|verify|submit|renew)\b",
            re.I,
        ),
    ),
    (
        "payment.pay_to_receive",
        "PAYMENT_MANIPULATION",
        4,
        "Suggests sending money or approving a collect request to receive a reward or refund.",
        re.compile(
            r"\b(?:pay|send|transfer|approve|accept)\b.{0,60}"
            r"\b(?:receive|claim|get)\b.{0,35}\b(?:refund|cashback|reward|prize|money)\b"
            r"|\b(?:pay|send|transfer|approve|accept)\b.{0,35}\b(?:collect request|collect payment)\b",
            re.I,
        ),
    ),
    (
        "lottery.advance.fee",
        "PAYMENT_MANIPULATION",
        4,
        "Lottery or prize language is paired with an advance-fee request.",
        re.compile(
            r"\b(?:lottery|won|winner|prize|jackpot)\b.{0,80}\b(?:fee|tax|charge|pay|payment)\b"
            r"|\b(?:fee|tax|charge|pay|payment)\b.{0,80}\b(?:lottery|prize|jackpot)\b",
            re.I,
        ),
    ),
    (
        "job.registration.fee",
        "PAYMENT_MANIPULATION",
        3,
        "A job or registration offer is paired with a requested fee.",
        re.compile(
            r"\b(?:job|employment|work from home|registration)\b.{0,70}\b(?:fee|deposit|pay|payment)\b"
            r"|\b(?:fee|deposit)\b.{0,70}\b(?:job|employment|registration)\b",
            re.I,
        ),
    ),
    (
        "impersonation.authority",
        "IMPERSONATION",
        3,
        "Claims to represent a bank, government body, or official support channel.",
        re.compile(
            r"\b(?:bank|government|police|income tax|rbi|customer support)\b"
            r".{0,50}\b(?:official|department|team|officer|agent|helpline)\b",
            re.I,
        ),
    ),
    (
        "remote_access.install",
        "REMOTE_ACCESS_SCAM",
        5,
        "Asks the recipient to install remote-access software or share their screen.",
        re.compile(
            r"\b(?:install|download)\b.{0,50}\b(?:anydesk|teamviewer|remote access|screen sharing)\b"
            r"|\b(?:anydesk|teamviewer|remote access|screen sharing)\b.{0,50}"
            r"\b(?:install|download|allow|share)\b",
            re.I,
        ),
    ),
    (
        "pressure.urgent.deadline",
        "URGENCY_OR_THREAT",
        3,
        "Uses urgent timing or a short deadline to pressure action.",
        re.compile(
            r"\b(?:immediately|right now|within\s+\d+\s*(?:minutes?|hours?)|"
            r"today only|act now|urgent|asap|before\s+\d{1,2}\s*(?:am|pm))\b",
            re.I,
        ),
    ),
)


def detect_patterns(value: str) -> list[dict[str, Any]]:
    """Return unique rule findings with the exact matched evidence."""
    findings: list[dict[str, Any]] = []
    seen: set[str] = set()
    for rule_id, category, severity, explanation, pattern in _RULES:
        match = next(
            (
                candidate
                for candidate in pattern.finditer(value)
                if not re.search(
                    r"\b(?:do not|don't|never|should not|must not|will not|won't)"
                    r"(?:\s+\w+){0,5}\s*$",
                    value[max(0, candidate.start() - 40) : candidate.start()],
                    re.I,
                )
            ),
            None,
        )
        if not match or rule_id in seen:
            continue
        seen.add(rule_id)
        findings.append(
            {
                "rule_id": rule_id,
                "category": category,
                "evidence": match.group(0).strip()[:300],
                "severity": severity,
                "explanation": explanation,
                "source": "deterministic",
            }
        )
    return findings


def normalize_text(value: str) -> str:
    """Compatibility helper retained for existing package consumers."""
    return re.sub(r"\s+", " ", (value or "")).strip().lower()


def keyword_hits(value: str) -> list[str]:
    """Return rule identifiers for patterns supported by the current detector."""
    return [finding["rule_id"] for finding in detect_patterns(value)]


def url_red_flags(url: str) -> list[str]:
    """Return suspicious lexical URL tokens without visiting the URL."""
    return [
        token
        for token in ("verify", "login", "secure", "claim", "bonus", "redirect", "otp", "kyc")
        if token in (url or "").lower()
    ]
