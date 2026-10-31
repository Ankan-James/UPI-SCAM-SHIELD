"""Optional Tesseract OCR adapter with explicit runtime limitations."""

from __future__ import annotations

from dataclasses import dataclass

from PIL import Image

from agent.config import get_settings
from agent.processing.image_processor import process_image


class OCRUnavailable(RuntimeError):
    """Raised when the OCR library or Tesseract executable is unavailable."""


@dataclass(frozen=True)
class OCRResult:
    text: str
    confidence: float | None
    limitations: list[str]


def extract_text(image: Image.Image) -> OCRResult:
    """Extract text with Tesseract; confidence is an OCR quality estimate."""
    try:
        import pytesseract
        from pytesseract import TesseractNotFoundError
    except ImportError as exc:
        raise OCRUnavailable("Install pytesseract and the Tesseract executable for OCR") from exc
    try:
        data = pytesseract.image_to_data(
            image,
            lang=get_settings().ocr_language,
            output_type=pytesseract.Output.DICT,
            timeout=get_settings().ocr_timeout,
        )
    except TesseractNotFoundError as exc:
        raise OCRUnavailable("Tesseract executable was not found") from exc
    except RuntimeError as exc:
        raise OCRUnavailable(f"Tesseract OCR failed or timed out: {exc}") from exc
    confidences: list[float] = []
    words: list[str] = []
    for word, raw_confidence in zip(data.get("text", []), data.get("conf", [])):
        if word.strip():
            words.append(word.strip())
        try:
            confidence = float(raw_confidence)
        except (TypeError, ValueError):
            continue
        if confidence >= 0:
            confidences.append(confidence)
    average = sum(confidences) / len(confidences) / 100 if confidences else None
    limitations = ["OCR may misread financial identifiers or instructions."]
    if average is None or average < 0.5:
        limitations.append("OCR confidence is low or unavailable; verify the source image.")
    return OCRResult(" ".join(words), average, limitations)


def extract_text_from_bytes(image_bytes: bytes) -> OCRResult:
    """Validate an image and extract its text."""
    processed = process_image(image_bytes)
    return extract_text(processed.image)
