"""Public, backwards-compatible scam-analysis entry points."""

from __future__ import annotations

from typing import Any

from agent.detection.scam_detector import ScamDetector
from agent.schemas.analysis_schema import AnalysisRequest, AnalysisResult, InputType

_DEFAULT_DETECTOR = ScamDetector()


def analyze(request: AnalysisRequest | dict[str, Any]) -> AnalysisResult:
    """Analyze a request through the standalone NUMPE agent."""
    return _DEFAULT_DETECTOR.analyze(request)


def analyze_input(input_type: str, value: str) -> dict[str, Any]:
    """Preserve the result shape consumed by the existing backend adapter."""
    normalized_type = input_type.strip().lower()
    normalized_type = {"upi_id": "recipient", "image": "screenshot"}.get(
        normalized_type, normalized_type
    )
    result = analyze(
        AnalysisRequest(
            input_type=InputType(normalized_type),
            content=value,
        )
    )
    indicators = [item.evidence for item in result.indicators]
    return {
        "type": result.input_type.value,
        "score": result.risk_score,
        "level": result.risk_level.value,
        "indicators": indicators,
        "recommendation": result.recommendation,
        "analysis": result.model_dump(mode="json"),
        "status": result.status,
    }
