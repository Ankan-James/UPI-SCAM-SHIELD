"""Scam detection for URLs and links."""

from __future__ import annotations

from urllib.parse import urlparse

from .scam_patterns import url_red_flags


def analyze_url(value: str) -> dict:
    url = (value or '').strip()
    indicators: list[str] = []
    score = 0
    parsed = urlparse(url)

    if not parsed.scheme or not parsed.netloc:
        score += 25
        indicators.append("Malformed URL")

    if parsed.hostname and any(host in parsed.hostname for host in ['bit.ly', 'tinyurl', 't.co', 'shorturl']):
        score += 40
        indicators.append('URL shortener detected')

    if any(flag in url.lower() for flag in ['verify', 'secure', 'claim', 'login', 'bonus', 'redirect']):
        score += 20
        indicators.append('Link uses pressure or credential language')

    for flag in url_red_flags(url):
        score += 8
        indicators.append(f'Flagged URL token: {flag}')

    if parsed.hostname and parsed.hostname.count('.') == 0:
        score += 10
        indicators.append('Unexpected host format')

    score = min(score, 100)
    return {
        "score": score,
        "indicators": sorted(set(indicators)),
        "risk_level": "high" if score >= 70 else "medium" if score >= 35 else "low",
    }
