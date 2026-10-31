"""Safe in-memory image validation and normalization."""

from __future__ import annotations

import warnings
from dataclasses import dataclass
from io import BytesIO

from PIL import Image, UnidentifiedImageError

from agent.config import get_settings


class ImageProcessingError(ValueError):
    """Raised for invalid or oversized image input."""


@dataclass(frozen=True)
class ProcessedImage:
    image: Image.Image
    format: str
    width: int
    height: int


def process_image(image_bytes: bytes) -> ProcessedImage:
    """Validate image bytes and return a detached RGB image."""
    if not image_bytes:
        raise ImageProcessingError("Image input is empty")
    if len(image_bytes) > get_settings().max_image_size:
        raise ImageProcessingError("Image exceeds MAX_IMAGE_SIZE")
    try:
        with warnings.catch_warnings():
            warnings.simplefilter("error", Image.DecompressionBombWarning)
            with Image.open(BytesIO(image_bytes)) as source:
                source.verify()
            with Image.open(BytesIO(image_bytes)) as source:
                image_format = source.format or "unknown"
                if image_format not in {"PNG", "JPEG", "WEBP", "BMP"}:
                    raise ImageProcessingError(f"Image format is not supported: {image_format}")
                source.load()
                image = source.convert("RGB")
                return ProcessedImage(image, image_format, image.width, image.height)
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError) as exc:
        raise ImageProcessingError(f"Image is invalid or unsupported: {exc}") from exc
    except Image.DecompressionBombWarning as exc:
        raise ImageProcessingError("Image dimensions exceed the safe processing limit") from exc
