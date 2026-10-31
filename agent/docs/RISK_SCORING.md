# Risk scoring

Risk is calculated in Python from validated evidence. The Gemma response has no
final-score field and its confidence is not interpreted as a fraud probability.

## Default contributions

Each risk family contributes at most its configured weight. The strongest
indicator in a family wins; duplicate signals do not stack. For each indicator:

```text
family contribution = round(family weight * severity / 5)
total score = min(100, sum(family contributions))
```

| Family | Default maximum |
|---|---:|
| Dangerous credential requests | 30 |
| Suspicious URL / phishing structure | 25 |
| Urgency, threats, and social engineering | 15 |
| Impersonation / KYC context | 15 |
| Payment manipulation, remote access, and QR anomalies | 15 |

The default family weights total 100. They can be adjusted with `RISK_*_WEIGHT`
environment variables; the final total is clamped to 100. A missing reputation
record adds no evidence and never reduces a score.

## Classification thresholds

- `LOW`: 0-29
- `MEDIUM`: 30-69
- `HIGH`: 70-100

Thresholds are configurable using `RISK_LOW_MAX` and `RISK_MEDIUM_MAX`.

## Evidence and model contribution

Every deterministic indicator records its rule, matched text, severity, and
explanation. The scorer removes duplicate rule/evidence pairs. Model suggestions
are accepted only when the quoted indicator appears in the analyzed text and
are assigned severity 1; the model cannot directly supply a score. A weak
indicator can still be displayed without making `is_suspicious` true if its
weighted score is zero.

## Limitations and calibration

These are provisional prototype values, not calibrated financial-risk
probabilities. The weights and thresholds need review against a representative,
privacy-reviewed labelled dataset and the deployment's false-positive costs.
Evaluation results on the small synthetic examples are not production
performance claims. The current deterministic rules are English-first; the
multilingual sample illustrates a known false negative. Unknown domains,
valid QR syntax, absence of reputation reports, and low scores do not establish
safety.
