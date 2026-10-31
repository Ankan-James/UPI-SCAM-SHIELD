from dataclasses import replace

from agent.agent import analyze, analyze_input
from agent.config import get_settings
from agent.detection.scam_detector import ScamDetector
from agent.schemas.analysis_schema import AnalysisRequest


def test_standalone_pipeline_returns_partial_and_compatible_result():
    settings = replace(get_settings(), gemma_provider="disabled")
    detector = ScamDetector(settings=settings)
    result = detector.analyze(
        AnalysisRequest(
            analysis_id="test-1",
            input_type="text",
            content="Your account will be blocked. Share your OTP to complete KYC.",
        )
    )
    assert result.status == "partial"
    assert result.is_suspicious
    assert result.risk_score > 0
    assert result.scam_type == "OTP_FRAUD"
    legacy = analyze_input("text", "Share your OTP")
    assert {"score", "level", "indicators", "recommendation", "type"} <= legacy.keys()


def test_model_signal_must_be_grounded_in_input():
    settings = replace(get_settings(), gemma_provider="ollama")

    class MockGemma:
        def generate(self, _prompt):
            return (
                '{"scam_type":"PHISHING","is_suspicious":true,'
                '"indicators":["made-up phrase"],"confidence":0.99}'
            )

    result = ScamDetector(settings=settings, gemma_client=MockGemma()).analyze(
        AnalysisRequest(input_type="text", content="Hello, your payment was received.")
    )
    assert result.metadata.model_used
    assert not result.is_suspicious
    assert result.risk_score == 0


def test_invalid_qr_returns_failed_result():
    settings = replace(get_settings(), gemma_provider="disabled")
    result = ScamDetector(settings=settings).analyze(
        AnalysisRequest(input_type="qr", content="not a UPI QR")
    )
    assert result.status == "failed"
    assert "could not be completed" in result.explanation.lower()


def test_public_interface_accepts_dictionary():
    result = analyze({"analysis_id": "api", "input_type": "url", "content": "https://example.org"})
    assert result.analysis_id == "api"


def test_scam_category_uses_specific_evidence():
    settings = replace(get_settings(), gemma_provider="disabled")
    detector = ScamDetector(settings=settings)
    lottery = detector.analyze(
        AnalysisRequest(
            input_type="text",
            content="You won a lottery prize. Pay a processing fee to claim it.",
        )
    )
    pin = detector.analyze(
        AnalysisRequest(
            input_type="text",
            content="Share your UPI PIN with our agent now.",
        )
    )
    assert lottery.scam_type == "LOTTERY_FRAUD"
    assert pin.scam_type == "UPI_PIN_FRAUD"


def test_configured_text_size_limit_is_enforced():
    settings = replace(
        get_settings(),
        gemma_provider="disabled",
        max_input_length=10,
    )
    result = ScamDetector(settings=settings).analyze(
        AnalysisRequest(input_type="text", content="This message is over ten characters")
    )
    assert result.status == "failed"
    assert "size limit" in result.metadata.limitations[0]
