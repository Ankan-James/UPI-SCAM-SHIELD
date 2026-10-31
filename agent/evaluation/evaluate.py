"""Run labelled deterministic evaluation without requiring a live Gemma model."""

from __future__ import annotations

import json
import time
from dataclasses import replace
from pathlib import Path
from typing import Any

from agent.config import get_settings
from agent.detection.scam_detector import ScamDetector
from agent.evaluation.metrics import compute_metrics
from agent.schemas.analysis_schema import AnalysisRequest

DATASET = Path(__file__).with_name("test_cases.json")


def evaluate_samples(samples: list[dict[str, Any]]) -> dict[str, Any]:
    """Evaluate the deterministic pipeline against caller-supplied labels."""
    detector = ScamDetector(settings=replace(get_settings(), gemma_provider="disabled"))
    expected: list[bool] = []
    predicted: list[bool] = []
    latencies: list[float] = []
    json_valid: list[bool] = []
    results: list[dict[str, Any]] = []
    for index, sample in enumerate(samples):
        started = time.perf_counter()
        result = detector.analyze(
            AnalysisRequest(
                analysis_id=f"evaluation-{index}",
                input_type=sample["input_type"],
                content=sample["content"],
                context=sample.get("context", {}),
            )
        )
        latency_ms = (time.perf_counter() - started) * 1000
        expected.append(bool(sample["expected_suspicious"]))
        predicted.append(result.is_suspicious)
        latencies.append(latency_ms)
        json_valid.append(bool(result.model_dump_json()))
        results.append(
            {
                "id": sample.get("id", str(index)),
                "expected_suspicious": expected[-1],
                "predicted_suspicious": predicted[-1],
                "risk_score": result.risk_score,
                "status": result.status,
            }
        )
    return {
        "mode": "deterministic_only",
        "results": results,
        "metrics": compute_metrics(
            expected,
            predicted,
            latencies_ms=latencies,
            json_valid=json_valid,
        ),
    }


def main() -> int:
    """Load the checked-in labelled cases and print reproducible results."""
    with DATASET.open(encoding="utf-8") as file:
        cases = json.load(file)
    report = evaluate_samples(cases)
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
