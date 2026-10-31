"""Minimal evaluation harness for scam detection rules."""

from __future__ import annotations

from agent.agent import analyze_input


def evaluate_samples(samples: list[tuple[str, str]]) -> dict:
    results = []
    for sample_type, sample_value in samples:
        result = analyze_input(sample_type, sample_value)
        results.append({"type": sample_type, "input": sample_value, "score": result["score"], "level": result["level"]})
    return {"results": results, "average_score": round(sum(item["score"] for item in results) / len(results), 2) if results else 0}
