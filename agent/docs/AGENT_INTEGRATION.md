# Backend integration

## Install and import

Install `agent/requirements.txt` in the same Python environment as the caller.
The package can be imported from the repository root:

```python
from agent import analyze
from agent.schemas import AnalysisRequest

request = AnalysisRequest(
    analysis_id="ANL001",
    input_type="text",
    content="Your account will be blocked. Share your OTP.",
    context={},
)
result = analyze(request)
response = result.model_dump(mode="json")
```

The synchronous public signature is:

```python
analyze(request: AnalysisRequest | dict) -> AnalysisResult
```

`analyze_input(input_type, value)` remains available for the current backend
adapter and preserves its `score`, `level`, `indicators`, `recommendation`, and
`type` fields. New integrations should use the validated request/result models.

## Request contract

| Field | Type | Notes |
|---|---|---|
| `analysis_id` | string | Caller-provided correlation ID; generated if omitted. |
| `input_type` | string | `text`, `url`, `qr`, `screenshot`, or `recipient`. |
| `content` | string | Text/URL/recipient/decoded UPI payload, or base64 image content. |
| `context` | object | Optional; `reputation` may carry caller-supplied reputation evidence. |

Contexts are limited to 20,000 serialized characters. Do not treat caller-supplied
user IDs as authentication. The backend remains responsible for authorization,
storage, and payment decisions.

QR and screenshot image inputs accept `base64:<encoded bytes>` or a
`data:image/...;base64,...` string. Raw file paths are not read by the package.
The CLI can read a path explicitly when invoked with `--file`.

## Response contract

`AnalysisResult` contains `analysis_id`, `status`, `input_type`,
`is_suspicious`, `risk_score` (0-100), `risk_level` (`LOW`, `MEDIUM`, `HIGH`),
`scam_type`, evidence-bearing `indicators`, `explanation`, `recommendation`,
qualitative `confidence`, and `metadata`.

Each indicator includes `rule_id`, `category`, matched `evidence`, `severity`
(1-5), `explanation`, and `source`. Do not infer proof of fraud from a category
or a single report.

Statuses:

- `completed`: requested processing completed, including configured model work.
- `partial`: deterministic analysis returned, but optional model/OCR/QR
  components were unavailable or limited.
- `failed`: required input processing failed; do not rely on the empty risk score.

Model timeouts and invalid model output are represented as limitations and do
not erase deterministic findings. Configure `GEMMA_TIMEOUT` and `GEMMA_RETRIES`
to suit the caller's latency budget.

## Reputation input

Pass data through `context.reputation`, for example:

```json
{
  "state": "SUSPICIOUS_REPORTED",
  "reports": [
    {"verified": false}
  ]
}
```

Allowed states: `TRUSTED_DATA_AVAILABLE`, `SUSPICIOUS_REPORTED`,
`VALIDATED_RISK_INDICATORS`, `UNKNOWN`. Only verified reports or validated risk
indicators create weighted risk evidence. Unverified reports remain visible as
weak claims and do not mark the recipient suspicious. No source or reputation
record is invented by this agent.

## Operational notes

- Gemma uses the configured Ollama runtime; set `GEMMA_PROVIDER=disabled` for
  deterministic-only operation.
- QR image decoding requires OpenCV. Screenshot OCR requires both `pytesseract`
  and the Tesseract executable. Both are optional and failures are explicit.
- The package never starts a server, visits a submitted URL, executes content,
  approves a payment, or stores requests.
- If Gemma is configured to a non-local host, assess that provider's data
  handling before sending financial messages or OCR text.
