"""Reproducible binary-classification and runtime metrics."""

from __future__ import annotations

from collections.abc import Sequence
from typing import Any


def compute_metrics(
    expected: Sequence[bool],
    predicted: Sequence[bool],
    *,
    latencies_ms: Sequence[float] | None = None,
    json_valid: Sequence[bool] | None = None,
) -> dict[str, Any]:
    """Calculate accuracy, precision, recall, F1, false-positive rate, latency, and validity."""
    if len(expected) != len(predicted):
        raise ValueError("expected and predicted must have equal lengths")
    if not expected:
        raise ValueError("at least one labelled result is required")
    if latencies_ms is not None and len(latencies_ms) != len(expected):
        raise ValueError("latencies_ms must match the number of examples")
    if json_valid is not None and len(json_valid) != len(expected):
        raise ValueError("json_valid must match the number of examples")
    tp = sum(actual and guess for actual, guess in zip(expected, predicted))
    tn = sum(not actual and not guess for actual, guess in zip(expected, predicted))
    fp = sum(not actual and guess for actual, guess in zip(expected, predicted))
    fn = sum(actual and not guess for actual, guess in zip(expected, predicted))
    precision = tp / (tp + fp) if tp + fp else 0.0
    recall = tp / (tp + fn) if tp + fn else 0.0
    return {
        "count": len(expected),
        "accuracy": (tp + tn) / len(expected),
        "precision": precision,
        "recall": recall,
        "f1": 2 * precision * recall / (precision + recall) if precision + recall else 0.0,
        "false_positive_rate": fp / (fp + tn) if fp + tn else 0.0,
        "average_latency_ms": sum(latencies_ms) / len(latencies_ms) if latencies_ms else None,
        "json_validity_rate": sum(json_valid) / len(json_valid) if json_valid else None,
        "confusion_matrix": {"true_positive": tp, "true_negative": tn, "false_positive": fp, "false_negative": fn},
    }
