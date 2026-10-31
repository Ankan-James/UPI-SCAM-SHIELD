"""Simple text normalization utilities for scam analysis."""

from __future__ import annotations

import re


def clean_text(value: str) -> str:
    normalized = (value or "").replace("\r", " ").replace("\n", " ")
    return re.sub(r"\s+", " ", normalized).strip()


def to_lower(value: str) -> str:
    return clean_text(value).lower()
