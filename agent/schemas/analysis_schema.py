"""Pydantic schemas used at agent boundaries."""

from __future__ import annotations

import json
from enum import StrEnum
from typing import Any
from uuid import uuid4

from pydantic import BaseModel, ConfigDict, Field, field_validator


class InputType(StrEnum):
    TEXT = "text"
    URL = "url"
    QR = "qr"
    SCREENSHOT = "screenshot"
    RECIPIENT = "recipient"


class RiskLevel(StrEnum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"


class ScamCategory(StrEnum):
    OTP_FRAUD = "OTP_FRAUD"
    UPI_PIN_FRAUD = "UPI_PIN_FRAUD"
    KYC_FRAUD = "KYC_FRAUD"
    PHISHING = "PHISHING"
    LOTTERY_FRAUD = "LOTTERY_FRAUD"
    JOB_FRAUD = "JOB_FRAUD"
    IMPERSONATION = "IMPERSONATION"
    REMOTE_ACCESS_SCAM = "REMOTE_ACCESS_SCAM"
    PAYMENT_MANIPULATION = "PAYMENT_MANIPULATION"
    SOCIAL_ENGINEERING = "SOCIAL_ENGINEERING"
    SUSPICIOUS_URL = "SUSPICIOUS_URL"
    SUSPICIOUS_QR = "SUSPICIOUS_QR"
    NORMAL = "NORMAL"
    UNKNOWN = "UNKNOWN"


class AnalysisRequest(BaseModel):
    """Validated request accepted by the public agent interface."""

    model_config = ConfigDict(extra="forbid")

    analysis_id: str = Field(
        default_factory=lambda: str(uuid4()),
        min_length=1,
        max_length=128,
    )
    input_type: InputType
    content: str = Field(min_length=1, max_length=14_000_000)
    context: dict[str, Any] = Field(default_factory=dict)

    @field_validator("analysis_id", "content")
    @classmethod
    def reject_blank_strings(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("must not be blank")
        return value

    @field_validator("context")
    @classmethod
    def limit_context_size(cls, value: dict[str, Any]) -> dict[str, Any]:
        try:
            serialized = json.dumps(value, ensure_ascii=False)
        except (TypeError, ValueError) as exc:
            raise ValueError("context must contain JSON-compatible values") from exc
        if len(serialized) > 20_000:
            raise ValueError("context must not exceed 20000 characters")
        return value


class DetectionIndicator(BaseModel):
    """An explainable signal with evidence and provenance."""

    model_config = ConfigDict(extra="forbid")

    rule_id: str = Field(min_length=1)
    category: str = Field(min_length=1)
    evidence: str = Field(min_length=1)
    severity: int = Field(ge=1, le=5)
    explanation: str = Field(min_length=1)
    source: str = "deterministic"


class RiskClassification(BaseModel):
    """Risk score and its corresponding classification."""

    score: int = Field(ge=0, le=100)
    level: RiskLevel


class AnalysisMetadata(BaseModel):
    """Non-sensitive metadata about pipeline completion."""

    limitations: list[str] = Field(default_factory=list)
    model_used: bool = False
    processing_ms: float | None = Field(default=None, ge=0)


class AnalysisResult(BaseModel):
    """Stable validated analysis response returned to callers."""

    model_config = ConfigDict(extra="forbid")

    analysis_id: str
    status: str
    input_type: InputType
    is_suspicious: bool
    risk_score: int = Field(ge=0, le=100)
    risk_level: RiskLevel
    scam_type: ScamCategory
    indicators: list[DetectionIndicator] = Field(default_factory=list)
    explanation: str
    recommendation: str
    confidence: float = Field(ge=0, le=1)
    metadata: AnalysisMetadata = Field(default_factory=AnalysisMetadata)

    @field_validator("status")
    @classmethod
    def validate_status(cls, value: str) -> str:
        if value not in {"completed", "partial", "failed"}:
            raise ValueError("status must be completed, partial, or failed")
        return value


class AnalysisError(BaseModel):
    """Structured, non-sensitive failure details."""

    code: str
    message: str


class ModelAnalysis(BaseModel):
    """Constrained interpretation returned by Gemma, never a final score."""

    model_config = ConfigDict(extra="ignore")

    scam_type: ScamCategory = ScamCategory.UNKNOWN
    is_suspicious: bool = False
    indicators: list[str] = Field(default_factory=list, max_length=20)
    explanation: str = Field(default="", max_length=2_000)
    recommendation: str = Field(default="", max_length=1_000)
    confidence: float = Field(default=0.0, ge=0, le=1)

    @field_validator("indicators")
    @classmethod
    def trim_indicators(cls, values: list[str]) -> list[str]:
        return [item.strip()[:300] for item in values if item.strip()]
