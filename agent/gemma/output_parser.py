"""Strict parsing and validation of structured Gemma output."""

from __future__ import annotations

import json
from typing import Any

from pydantic import ValidationError

from agent.schemas.analysis_schema import ModelAnalysis


class ModelOutputError(ValueError):
    """Raised when model output cannot be safely interpreted."""


def _extract_json_object(text: str) -> str:
    """Extract the first complete JSON object, respecting quoted braces."""
    start = text.find("{")
    if start < 0:
        raise ModelOutputError("Model output did not contain a JSON object")
    depth = 0
    in_string = False
    escaped = False
    for index in range(start, len(text)):
        char = text[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue
        if char == '"':
            in_string = True
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[start : index + 1]
    raise ModelOutputError("Model output contained an incomplete JSON object")


def parse_model_output(payload: str | dict[str, Any]) -> ModelAnalysis:
    """Parse model JSON and validate only supported analysis fields."""
    try:
        if isinstance(payload, str):
            if len(payload) > 20_000:
                raise ModelOutputError("Model output exceeds the allowed size")
            data = json.loads(_extract_json_object(payload))
        elif isinstance(payload, dict):
            data = payload
        else:
            raise ModelOutputError("Model output must be JSON text or an object")
        if not isinstance(data, dict):
            raise ModelOutputError("Model output JSON must be an object")
        return ModelAnalysis.model_validate(data)
    except (json.JSONDecodeError, ValidationError) as exc:
        raise ModelOutputError(f"Model output failed validation: {exc}") from exc
