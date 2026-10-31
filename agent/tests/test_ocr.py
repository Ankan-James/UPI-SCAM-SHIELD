import sys
from types import ModuleType, SimpleNamespace

from PIL import Image

from agent.processing.ocr_processor import extract_text


def test_ocr_result_includes_quality_metadata(monkeypatch):
    fake = ModuleType("pytesseract")
    fake.image_to_data = lambda *_args, **_kwargs: {
        "text": ["Account", "blocked"],
        "conf": ["90", "80"],
    }
    fake.Output = SimpleNamespace(DICT="dict")
    fake.TesseractNotFoundError = RuntimeError
    monkeypatch.setitem(sys.modules, "pytesseract", fake)
    result = extract_text(Image.new("RGB", (2, 2)))
    assert result.text == "Account blocked"
    assert result.confidence == 0.85
    assert result.limitations
