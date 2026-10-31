"""Text normalization and extraction of relevant payment evidence."""

from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass

from agent.config import get_settings

URL_PATTERN = re.compile(r"""(?i)\b(?:https?://|www\.)[^\s<>"']+""")
UPI_PATTERN = re.compile(r"(?i)\b[a-z0-9._-]{2,256}@[a-z][a-z0-9.-]{1,63}\b")
PHONE_PATTERN = re.compile(r"(?<!\w)(?:\+?91[\s-]?)?[6-9]\d{9}(?!\w)")


class InputValidationError(ValueError):
    """Raised when an input is empty, unsupported, or exceeds configured limits."""


@dataclass(frozen=True)
class ProcessedText:
    original: str
    normalized: str
    urls: list[str]
    upi_ids: list[str]
    phone_numbers: list[str]


def process_text(value: str) -> ProcessedText:
    """Normalize text without discarding the original evidence."""
    if not isinstance(value, str) or not value.strip():
        raise InputValidationError("Text input must not be empty")
    if len(value) > get_settings().max_input_length:
        raise InputValidationError("Text input exceeds MAX_INPUT_LENGTH")
    normalized = unicodedata.normalize("NFC", value)
    normalized = re.sub(r"[\r\n\t]+", " ", normalized)
    normalized = re.sub(r"\s+", " ", normalized).strip()
    urls = [match.rstrip(".,;:!?)]}") for match in URL_PATTERN.findall(normalized)]
    return ProcessedText(
        original=value,
        normalized=normalized,
        urls=urls,
        upi_ids=UPI_PATTERN.findall(normalized),
        phone_numbers=PHONE_PATTERN.findall(normalized),
    )
