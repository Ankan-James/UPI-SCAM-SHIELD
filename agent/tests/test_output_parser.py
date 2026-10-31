import pytest

from agent.gemma.output_parser import ModelOutputError, parse_model_output


def test_parser_extracts_json_from_code_fence():
    result = parse_model_output(
        '```json\n{"scam_type":"OTP_FRAUD","is_suspicious":true,'
        '"indicators":["OTP request"],"confidence":0.8}\n```'
    )
    assert result.scam_type == "OTP_FRAUD"
    assert result.indicators == ["OTP request"]


@pytest.mark.parametrize("payload", ["not json", "{bad}", "[]", '{"confidence":2}'])
def test_parser_rejects_malformed_or_unsupported_output(payload):
    with pytest.raises(ModelOutputError):
        parse_model_output(payload)
