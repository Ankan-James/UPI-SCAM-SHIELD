from agent.detection.risk_scorer import calculate_risk, score_findings


def test_legacy_threshold_boundaries():
    assert calculate_risk(29)["level"] == "LOW"
    assert calculate_risk(30)["level"] == "MEDIUM"
    assert calculate_risk(69)["level"] == "MEDIUM"
    assert calculate_risk(70)["level"] == "HIGH"


def test_duplicate_signals_do_not_stack_and_gemma_score_is_not_used():
    finding = {
        "rule_id": "credential.otp.request",
        "category": "DANGEROUS_CREDENTIAL_REQUEST",
        "severity": 5,
        "evidence": "share OTP",
        "explanation": "OTP requested",
    }
    result = score_findings([finding, finding])
    assert result["score"] == 30
    assert len(result["indicators"]) == 1


def test_unrecognized_evidence_is_not_silently_classed_as_risk():
    result = score_findings(
        [{"rule_id": "unknown", "category": "UNVERIFIED_REPORT", "severity": 1, "evidence": "report"}]
    )
    assert result["score"] == 0
