"""Utility helpers for URL validation and suspicious-domain checks."""

from __future__ import annotations

from urllib.parse import urlparse


def is_valid_url(value: str) -> bool:
    try:
        parsed = urlparse(value)
        return bool(parsed.scheme and parsed.netloc)
    except Exception:
        return False


def has_suspicious_tld(value: str) -> bool:
    lowered = (value or "").lower()
    return any(domain in lowered for domain in (".tk", ".ml", "bit.ly", "tinyurl", "shorturl"))
