# Agent architecture

## Design

The agent is an importable Python package under `agent/`. It owns no database,
HTTP API server, authentication, payment authorization, or long-term storage.
`agent.agent.analyze()` is the validated public interface; the older
`analyze_input()` adapter remains for the existing backend integration.

```text
AnalysisRequest
      |
ScamDetector
      +-- text preprocessing and deterministic patterns
      +-- offline URL structure checks
      +-- UPI QR payload parsing / optional OpenCV decoding
      +-- image validation / optional Tesseract OCR
      +-- caller-provided recipient reputation checks
      +-- optional Gemma interpretation
      |
Python risk scoring and recommendation
      |
Validated AnalysisResult
```

## Components

- `config.py`: environment loading, bounds checks, scoring thresholds/weights,
  model and image/OCR limits.
- `schemas/`: Pydantic request, response, evidence, status, and model-output
  contracts.
- `gemma/`: Ollama-only model adapter, untrusted-input prompt builder, and
  strict model response parser. Detection code does not make HTTP requests.
- `processing/`: Unicode-aware text normalization, in-memory image validation,
  OCR, and UPI QR payload processing.
- `detection/`: rule patterns, URL heuristics, recipient evidence validation,
  risk scoring, and the single orchestrator.
- `evaluation/`: synthetic labelled examples, deterministic evaluation runner,
  and binary classification/runtime metrics.
- `tests/`: unit and integration tests using mocked model responses.

## Data flow and failure behavior

1. The caller constructs an `AnalysisRequest`; Pydantic validates its type,
   content, and bounded context.
2. The orchestrator routes the content to the appropriate local processor.
   URLs are never fetched; screenshots and QR images are validated in memory.
3. Deterministic detectors produce evidence-bearing indicators. Recipient
   reputation is accepted only from caller-supplied context.
4. If enabled, Gemma receives bounded, JSON-encoded untrusted content. Its
   response is schema-validated. Model-supplied scores are not consumed;
   model indicators contribute only when their evidence appears literally in
   the analyzed content, and then at low severity.
5. Python deduplicates indicators, calculates the score/classification, and
   validates the final response.
6. Missing optional runtimes, unavailable Gemma, rejected model output, and OCR
   limitations are surfaced in `metadata.limitations` and produce `partial`
   results. Invalid processing input produces an explicit `failed` result.

The agent does not persist requests. Callers should apply their own retention,
access-control, and privacy policies.
