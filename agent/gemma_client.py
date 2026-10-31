"""Local fallback client for the scam-analysis agent."""

from __future__ import annotations

import json
from typing import Any

from .detection.risk_scorer import calculate_risk


class GemmaClient:
    """Fallback client used when the bundled model is unavailable."""

    def analyze(self, input_type: str, value: str) -> dict[str, Any]:
        from .agent import analyze_input

        result = analyze_input(input_type, value)
        return {"status": "ok", "result": result}

    def parse_response(self, payload: str | dict[str, Any]) -> dict[str, Any]:
        if isinstance(payload, dict):
            return payload
        if payload is None:
            return {"score": 0, "level": "low", "indicators": [], "recommendation": "No issue detected."}
        try:
            data = json.loads(payload)
            if isinstance(data, dict):
                return data
        except json.JSONDecodeError:
            pass
        return {"score": 0, "level": "low", "indicators": ["Model output could not be parsed."], "recommendation": "Review manually."}
