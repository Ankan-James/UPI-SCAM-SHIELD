import httpx

from agent.config import get_settings
from agent.gemma.model import GemmaClient, GemmaUnavailable


def test_generate_uses_configured_model_and_extracts_response():
    captured = {}

    def handler(request):
        captured.update(request=json.loads(request.content))
        return httpx.Response(200, json={"response": '{"scam_type":"NORMAL"}'})

    import json

    client = GemmaClient(
        get_settings(),
        client=httpx.Client(transport=httpx.MockTransport(handler)),
    )
    assert client.generate("safe prompt") == '{"scam_type":"NORMAL"}'
    assert captured["request"]["model"] == get_settings().gemma_model
    client.close()


def test_generate_surfaces_runtime_failure():
    client = GemmaClient(
        get_settings(),
        client=httpx.Client(transport=httpx.MockTransport(
            lambda _: httpx.Response(503, json={"error": "unavailable"})
        )),
    )
    try:
        client.generate("prompt")
    except GemmaUnavailable as exc:
        assert "503" in str(exc)
    else:
        raise AssertionError("Unavailable runtime was silently accepted")
    finally:
        client.close()
