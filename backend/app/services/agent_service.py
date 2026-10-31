"""Adapter between the API layer and the scam-detection agent."""

from __future__ import annotations

from agent.agent import analyze_input


class AgentService:
    @staticmethod
    def analyze(input_type: str, value: str) -> dict:
        result = analyze_input(input_type, value)
        normalized = {
            "score": result.get("score", 0),
            "level": result.get("level", "low"),
            "indicators": result.get("indicators", []),
            "recommendation": result.get("recommendation", "No issue detected."),
            "type": input_type,
        }
        return normalized
