import pytest

from agent.detection.recipient_analyzer import analyze_recipient


def test_unknown_reputation_is_not_evidence_of_safety_or_risk():
    result = analyze_recipient("merchant@example")
    assert result["state"] == "UNKNOWN"
    assert result["findings"] == []
    assert "do not guarantee" in result["limitations"][-1]


def test_unverified_reports_are_not_treated_as_proof():
    result = analyze_recipient(
        "merchant@example",
        {"state": "SUSPICIOUS_REPORTED", "reports": [{"verified": False}]},
    )
    assert result["findings"][0]["severity"] == 1
    assert "not treated as proof" in result["findings"][0]["explanation"]


def test_invalid_recipient_rejected():
    with pytest.raises(ValueError):
        analyze_recipient("not a UPI ID")
