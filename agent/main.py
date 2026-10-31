"""Command-line tools for independent agent checks and analysis."""

from __future__ import annotations

import argparse
import json
import logging
import sys
from pathlib import Path

from agent.config import get_settings
from agent.gemma.model import GemmaClient
from agent.agent import analyze
from agent.schemas.analysis_schema import AnalysisRequest, InputType


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="NUMPE Scam Shield local CLI")
    parser.add_argument(
        "command",
        choices=("check-config", "health", "analyze"),
        help="configuration check, Gemma health check, or content analysis",
    )
    parser.add_argument("--type", choices=[kind.value for kind in InputType], default="text")
    source = parser.add_mutually_exclusive_group()
    source.add_argument("--input", help="text, URL, recipient, or UPI QR payload")
    source.add_argument("--file", type=Path, help="local QR/screenshot image for image input types")
    return parser


def main(argv: list[str] | None = None) -> int:
    """Run the CLI and return a process status code."""
    args = _parser().parse_args(argv)
    try:
        settings = get_settings()
    except ValueError as exc:
        print(json.dumps({"status": "error", "message": str(exc)}), file=sys.stderr)
        return 2
    logging.basicConfig(level=settings.log_level)
    if args.command == "check-config":
        print(json.dumps({"status": "ok", "provider": settings.gemma_provider, "model": settings.gemma_model}))
        return 0
    if args.command == "health":
        with GemmaClient(settings) as client:
            health = client.health_check()
        print(json.dumps(health))
        return 0 if health["available"] or settings.gemma_provider == "disabled" else 1
    if args.file is not None:
        if args.type not in {"qr", "screenshot"}:
            print("--file is supported only for qr or screenshot input", file=sys.stderr)
            return 2
        import base64

        try:
            content = "base64:" + base64.b64encode(args.file.read_bytes()).decode("ascii")
        except OSError as exc:
            print(f"Could not read image file: {exc}", file=sys.stderr)
            return 2
    elif args.input is not None:
        content = args.input
    else:
        print("Provide --input or --file", file=sys.stderr)
        return 2
    try:
        result = analyze(
            AnalysisRequest(
                input_type=args.type,
                content=content,
            )
        )
    except ValueError as exc:
        print(json.dumps({"status": "error", "message": str(exc)}), file=sys.stderr)
        return 2
    print(result.model_dump_json(indent=2))
    return 0 if result.status != "failed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
