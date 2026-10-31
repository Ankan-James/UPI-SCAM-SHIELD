from agent.detection.scam_patterns import detect_patterns
from agent.detection.text_analyzer import analyze_text_message
from agent.processing.text_processor import InputValidationError, process_text


def test_detects_credential_threat_and_kyc_context():
    result = analyze_text_message(
        "Your bank account will be blocked in two hours. Share your OTP to complete KYC."
    )
    rules = {finding["rule_id"] for finding in result["findings"]}
    assert "credential.otp.request" in rules
    assert "threat.account.suspension" in rules
    assert "kyc.urgent.update" in rules


def test_negated_credential_warning_is_not_a_credential_request():
    assert not detect_patterns("Never share your OTP or UPI PIN with anyone.")


def test_legitimate_payment_notice_has_no_obvious_rule_hit():
    assert analyze_text_message("Your payment of INR 500 was received successfully.")["score"] == 0


def test_text_processing_preserves_evidence_and_extracts_identifiers():
    original = "Pay merchant@bank using https://example.com"
    processed = process_text(original)
    assert processed.original == original
    assert processed.upi_ids == ["merchant@bank"]
    assert processed.urls == ["https://example.com"]


def test_empty_text_rejected():
    try:
        process_text("  ")
    except InputValidationError:
        pass
    else:
        raise AssertionError("Blank input was accepted")
