"""Rule-based scam detection for text or UPI IDs."""

from __future__ import annotations

from .scam_patterns import keyword_hits, normalize_text

SUSPICIOUS_PATTERNS = [
    "claim reward",
    "verify otp",
    "urgent payment",
    "bank update",
    "security code",
    "click here",
    "refund",
    "bonus",
]


def analyze_text_message(value: str) -> dict:
    text = normalize_text(value)
    matches = keyword_hits(text)
    score = 0
    indicators: list[str] = []

    urgency_terms = ["urgent", "immediately", "today only", "act now", "asap"]
    reward_terms = ["claim reward", "reward", "bonus", "prize", "cashback", "refund"]
    credential_terms = ["otp", "password", "mpin", "security code", "verify account", "kyc"]

    for term in urgency_terms:
        if term in text:
            score += 25
            indicators.append(f"Urgency marker: {term}")

    for term in reward_terms:
        if term in text:
            score += 25
            indicators.append(f"Reward or refund marker: {term}")

    for term in credential_terms:
        if term in text:
            score += 25
            indicators.append(f"Credential request: {term}")

    for phrase in SUSPICIOUS_PATTERNS:
        if phrase in text:
            indicators.append(phrase)
            score += 12

    if "@" in text and text.count("@") == 1:
        score += 8
        indicators.append("UPI-style identifier detected")

    if "unknown" in text or "not in contact" in text:
        score += 30
        indicators.append("Recipient is not a trusted contact")

    if "claim" in text or "reward" in text:
        score += 25
        indicators.append("Reward claim language detected")

    if len(text) > 180:
        score += 8
        indicators.append("Long message with repeated request")

    for category in matches:
        score += 10
        indicators.append(f"Risk keyword: {category}")

    score = min(score, 100)
    return {
        "score": score,
        "indicators": sorted(set(indicators)),
        "risk_level": "high" if score >= 70 else "medium" if score >= 35 else "low",
    }
