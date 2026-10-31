from io import BytesIO

import pytest
from PIL import Image

from agent.processing.image_processor import ImageProcessingError, process_image
from agent.processing.qr_processor import QRProcessingError, parse_upi_payload


def test_parse_upi_payload_fields():
    payload = parse_upi_payload(
        "upi://pay?pa=merchant%40example&pn=Merchant&am=500&cu=INR&tn=Order"
    )
    assert payload.payee_upi_id == "merchant@example"
    assert payload.payee_name == "Merchant"
    assert payload.amount == "500"
    assert payload.currency == "INR"
    assert payload.note == "Order"


@pytest.mark.parametrize(
    "payload",
    ["https://example.com", "upi://pay?pa=invalid", "upi://pay?pa=a%40bank&am=-1"],
)
def test_rejects_invalid_upi_payload(payload):
    with pytest.raises(QRProcessingError):
        parse_upi_payload(payload)


def test_image_processor_validates_and_normalizes_png():
    stream = BytesIO()
    Image.new("RGB", (4, 4), "white").save(stream, format="PNG")
    processed = process_image(stream.getvalue())
    assert processed.format == "PNG"
    assert processed.image.mode == "RGB"


def test_image_processor_rejects_corrupted_image():
    with pytest.raises(ImageProcessingError):
        process_image(b"not an image")
