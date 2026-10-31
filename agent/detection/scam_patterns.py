"""Regex and keyword dictionaries used to detect scam patterns."""

import re

SCAM_KEYWORDS = {
    "urgency": ["urgent", "immediately", "today only", "act now", "within minutes", "asap"],
    "reward": ["claim reward", "bonus", "free gift", "refund", "lottery", "prize", "cashback"],
    "security": ["otp", "password", "mpin", "security code", "verify account", "update kyc"],
    "threat": ["blocked", "suspended", "deactivate", "legal action", "police", "fraud alert"],
    "fake_contact": ["upi id", "contact", "customer support", "official team", "bank helpline"],
}

URL_RED_FLAGS = [
    "bit.ly",
    "tinyurl",
    "t.co",
    "shorturl",
    ".tk",
    ".ml",
    "redirect",
    "verify",
    "login",
    "secure",
    "claim",
    "bonus",
]


def normalize_text(value: str) -> str:
    return re.sub(r"\s+", " ", (value or "")).strip().lower()


def keyword_hits(value: str) -> list[str]:
    text = normalize_text(value)
    matches: list[str] = []
    for category, keywords in SCAM_KEYWORDS.items():
        for keyword in keywords:
            if keyword in text:
                matches.append(keyword)
                break
    return matches


def url_red_flags(url: str) -> list[str]:
    lowered = (url or "").lower()
    matches: list[str] = []
    for flag in URL_RED_FLAGS:
        if flag in lowered:
            matches.append(flag)
    return matches
