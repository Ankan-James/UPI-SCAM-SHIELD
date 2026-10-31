"""UPI QR decoding and payload parsing without initiating transactions."""

from __future__ import annotations

import re
from dataclasses import dataclass
from decimal import Decimal, InvalidOperation
from urllib.parse import parse_qsl, urlparse

from agent.processing.image_processor import process_image

_UPI_ID = re.compile(r"(?i)^[a-z0-9._-]{2,256}@[a-z][a-z0-9.-]{1,63}$")
_SUPPORTED = {"pa", "pn", "am", "cu", "tn", "mc", "tr", "url"}


class QRProcessingError(ValueError):
    """Raised for malformed, invalid, or unsupported QR payloads."""


class QRDecoderUnavailable(RuntimeError):
    """Raised when the optional OpenCV QR decoder is unavailable."""


@dataclass(frozen=True)
class UPIPayload:
    payload: str
    payee_upi_id: str | None
    payee_name: str | None
    amount: str | None
    currency: str | None
    note: str | None
    unsupported_fields: list[str]
    limitations: list[str]


def parse_upi_payload(payload: str) -> UPIPayload:
    """Parse a UPI payment URI and surface unsupported fields."""
    if not isinstance(payload, str) or not payload.strip():
        raise QRProcessingError("QR payload is empty")
    parsed = urlparse(payload.strip())
    if parsed.scheme.lower() != "upi" or parsed.netloc.lower() != "pay" or parsed.path not in {"", "/"}:
        raise QRProcessingError("QR payload is not a supported upi://pay URI")
    pairs = parse_qsl(parsed.query, keep_blank_values=True, max_num_fields=100)
    values: dict[str, str] = {}
    for key, value in pairs:
        normalized_key = key.lower()
        if normalized_key in values:
            raise QRProcessingError(f"QR payload contains duplicate field: {normalized_key}")
        values[normalized_key] = value
    payee_id = values.get("pa")
    if payee_id and not _UPI_ID.fullmatch(payee_id):
        raise QRProcessingError("QR payload contains an invalid payee UPI ID")
    amount = values.get("am") or None
    if amount is not None:
        try:
            parsed_amount = Decimal(amount)
        except InvalidOperation as exc:
            raise QRProcessingError("QR payload amount is invalid") from exc
        if not parsed_amount.is_finite() or parsed_amount <= 0:
            raise QRProcessingError("QR payload amount must be greater than zero")
        amount = format(parsed_amount, "f")
    currency = values.get("cu") or None
    if currency and not re.fullmatch(r"[A-Za-z]{3}", currency):
        raise QRProcessingError("QR payload currency must be a three-letter code")
    return UPIPayload(
        payload=payload,
        payee_upi_id=payee_id,
        payee_name=values.get("pn") or None,
        amount=amount,
        currency=currency.upper() if currency else None,
        note=values.get("tn") or None,
        unsupported_fields=sorted(set(values) - _SUPPORTED),
        limitations=[
            "A valid UPI payload does not establish that the recipient is trustworthy.",
            "QR analysis does not authorize or initiate a payment.",
        ],
    )


def decode_qr_image(image_bytes: bytes) -> str:
    """Decode a QR image with OpenCV, without opening any referenced URL."""
    process_image(image_bytes)
    try:
        import cv2
        import numpy as np
    except ImportError as exc:
        raise QRDecoderUnavailable(
            "Install opencv-python-headless and numpy to decode QR images"
        ) from exc
    image = cv2.imdecode(
        np.frombuffer(image_bytes, dtype=np.uint8),
        cv2.IMREAD_COLOR,
    )
    if image is None:
        raise QRProcessingError("Image could not be decoded for QR analysis")
    detector = cv2.QRCodeDetector()
    decoded, _, _ = detector.detectAndDecode(image)
    if not decoded:
        raise QRProcessingError("No readable QR code was found in the image")
    return decoded


def analyze_qr_image(image_bytes: bytes) -> UPIPayload:
    """Decode and parse one payment QR image."""
    return parse_upi_payload(decode_qr_image(image_bytes))
