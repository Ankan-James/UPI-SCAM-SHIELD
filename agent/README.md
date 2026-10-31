# NUMPE Scam Shield Agent

An independent Python package for analyzing UPI-related messages, URLs, payment
QR payloads, screenshots, and caller-supplied recipient reputation evidence. The
agent combines deterministic checks with optional Gemma context analysis. Python
validates the final response and calculates the risk score; the agent never
authorizes or initiates a payment.

## Requirements and installation

- Python 3.11 or newer
- Ollama with the configured Gemma model for contextual analysis (optional)
- Tesseract executable for OCR (optional)
- `opencv-python-headless` for QR image decoding (optional)

From the repository root:

```powershell
python -m pip install -r agent\requirements.txt
Copy-Item agent\.env.example agent\.env
```

Edit `agent/.env` as needed. The default model is `gemma3:4b` at
`http://localhost:11434`; model analysis is attempted when configured and
unavailable model service produces a `partial` result. Set
`GEMMA_PROVIDER=disabled` to run deterministic checks only. Tesseract is an
external executable and must be installed separately; screenshots return a
partial result if it is unavailable.

## Use the Python interface

```python
from agent import analyze
from agent.schemas import AnalysisRequest

result = analyze(
    AnalysisRequest(
        analysis_id="ANL001",
        input_type="text",
        content="Your account will be blocked. Share your OTP.",
    )
)
print(result.model_dump(mode="json"))
```

The backend-compatible `analyze_input(input_type, value)` entry point remains
available and preserves the existing `score`, `level`, `indicators`,
`recommendation`, and `type` result keys.

For screenshot or QR images, provide `content` as `base64:<encoded bytes>` or a
`data:image/...;base64,...` URI. A QR request may also contain a decoded
`upi://pay?...` payload. Recipient reputation is supplied in `context.reputation`;
the agent does not maintain a reputation database.

## Local CLI

```powershell
python -m agent.main check-config
python -m agent.main health
python -m agent.main analyze --type text --input "Share your OTP to receive a refund"
python -m agent.main analyze --type qr --file .\payment-qr.png
python -m agent.main analyze --type screenshot --file .\message.png
```

## Tests and evaluation

```powershell
python -m pytest agent\tests -q
python -m agent.evaluation.evaluate
```

Evaluation runs against a small checked-in synthetic dataset and does not
contact Gemma. Its metrics are development feedback, not evidence of production
accuracy or real-world fraud performance.

## Limitations

- Rule-based checks are intentionally conservative and currently English-first;
  the multilingual example in the evaluation set demonstrates an uncovered case.
- URL analysis inspects visible syntax only. It never visits a URL, and an
  unknown or suspicious-looking domain is not a confirmed threat.
- OCR may misread text and identifiers. Always verify extracted content.
- A syntactically valid QR code and an unknown recipient are not evidence of
  safety. Reputation claims are only as trustworthy as their external source.
- Model confidence is qualitative and is not a probability that fraud occurred.
- A low score or absence of findings is not a guarantee of safety.
