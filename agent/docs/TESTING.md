# Testing and evaluation

## Commands

From the repository root:

```powershell
python -m pytest agent\tests -q
python -m agent.evaluation.evaluate
```

Tests use mocked HTTP/model responses and run without Ollama, Tesseract, or
OpenCV. OCR behavior is tested with a mocked pytesseract adapter; image parsing
and UPI payload validation are exercised locally.

## Dataset format

`evaluation/test_cases.json` contains synthetic records with:

- `id`: stable case identifier
- `input_type`: supported public input type
- `content`: message, URL, recipient, or decoded UPI payload
- `context`: optional external context
- `expected_suspicious`: binary reference label

Cases cover ordinary payment notices, credential/KYC pressure, lottery and job
fee requests, URLs, QR payloads, recipient reputation, ambiguous content,
multilingual text, and prompt injection. Labels are examples for regression
testing, not a threat-intelligence feed.

## Metrics

The evaluation runner reports accuracy, precision, recall, F1, false-positive
rate, average latency, JSON-validity rate, and the confusion matrix. It runs in
deterministic-only mode and does not make model calls. The returned metrics
reflect only this checked-in sample and should not be generalized to real-world
scam prevalence or performance. Add independently reviewed labelled data before
using the metrics for calibration.

## Failure scenarios

Unit and integration tests exercise malformed model JSON, model HTTP failure,
prompt injection in content, invalid URL/QR/image data, recipient evidence
validation, no-model operation, duplicate signals, score boundaries, and
OCR/QR optional-runtime behavior.
