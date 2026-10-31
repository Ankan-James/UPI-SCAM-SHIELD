"""Central configuration for the independent scam-analysis agent."""

from __future__ import annotations

import os
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from urllib.parse import urlsplit

from dotenv import load_dotenv

AGENT_DIR = Path(__file__).resolve().parent
load_dotenv(AGENT_DIR / ".env")


def _read_int(name: str, default: int, minimum: int, maximum: int) -> int:
    raw = os.getenv(name, str(default))
    try:
        value = int(raw)
    except ValueError as exc:
        raise ValueError(f"{name} must be an integer") from exc
    if not minimum <= value <= maximum:
        raise ValueError(f"{name} must be between {minimum} and {maximum}")
    return value


def _read_float(name: str, default: float, minimum: float, maximum: float) -> float:
    raw = os.getenv(name, str(default))
    try:
        value = float(raw)
    except ValueError as exc:
        raise ValueError(f"{name} must be a number") from exc
    if not minimum <= value <= maximum:
        raise ValueError(f"{name} must be between {minimum} and {maximum}")
    return value


@dataclass(frozen=True)
class Settings:
    """Validated runtime settings loaded from environment variables."""

    gemma_provider: str
    gemma_base_url: str
    gemma_model: str
    gemma_timeout: int
    gemma_temperature: float
    gemma_retries: int
    max_input_length: int
    max_image_size: int
    ocr_timeout: int
    low_risk_max: int
    medium_risk_max: int
    dangerous_credential_weight: int
    suspicious_url_weight: int
    urgency_weight: int
    impersonation_weight: int
    payment_manipulation_weight: int
    ocr_language: str
    log_level: str

    @classmethod
    def from_env(cls) -> Settings:
        """Load and validate agent configuration."""
        provider = os.getenv("GEMMA_PROVIDER", "ollama").strip().lower()
        if provider not in {"ollama", "disabled"}:
            raise ValueError("GEMMA_PROVIDER must be 'ollama' or 'disabled'")
        base_url = os.getenv("GEMMA_BASE_URL", "http://localhost:11434").strip().rstrip("/")
        parsed_base_url = urlsplit(base_url)
        if (
            parsed_base_url.scheme not in {"http", "https"}
            or not parsed_base_url.hostname
            or parsed_base_url.username is not None
            or parsed_base_url.password is not None
        ):
            raise ValueError("GEMMA_BASE_URL must be an HTTP(S) URL with a hostname and no credentials")
        model = os.getenv("GEMMA_MODEL", "gemma3:4b").strip()
        if provider == "ollama" and not model:
            raise ValueError("GEMMA_MODEL must not be empty when Gemma is enabled")
        low_max = _read_int("RISK_LOW_MAX", 29, 0, 98)
        medium_max = _read_int("RISK_MEDIUM_MAX", 69, low_max + 1, 99)
        log_level = os.getenv("LOG_LEVEL", "INFO").strip().upper()
        if log_level not in {"DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"}:
            raise ValueError("LOG_LEVEL must be a standard Python logging level")
        return cls(
            gemma_provider=provider,
            gemma_base_url=base_url,
            gemma_model=model,
            gemma_timeout=_read_int("GEMMA_TIMEOUT", 120, 1, 600),
            gemma_temperature=_read_float("GEMMA_TEMPERATURE", 0.1, 0.0, 2.0),
            gemma_retries=_read_int("GEMMA_RETRIES", 1, 0, 5),
            max_input_length=_read_int("MAX_INPUT_LENGTH", 10_000, 1, 1_000_000),
            max_image_size=_read_int("MAX_IMAGE_SIZE", 10_485_760, 1, 10_485_760),
            ocr_timeout=_read_int("OCR_TIMEOUT", 30, 1, 300),
            low_risk_max=low_max,
            medium_risk_max=medium_max,
            dangerous_credential_weight=_read_int("RISK_CREDENTIAL_WEIGHT", 30, 0, 100),
            suspicious_url_weight=_read_int("RISK_URL_WEIGHT", 25, 0, 100),
            urgency_weight=_read_int("RISK_URGENCY_WEIGHT", 15, 0, 100),
            impersonation_weight=_read_int("RISK_IMPERSONATION_WEIGHT", 15, 0, 100),
            payment_manipulation_weight=_read_int("RISK_PAYMENT_WEIGHT", 15, 0, 100),
            ocr_language=os.getenv("OCR_LANGUAGE", "eng").strip() or "eng",
            log_level=log_level,
        )


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Return the process-wide validated settings instance."""
    return Settings.from_env()
