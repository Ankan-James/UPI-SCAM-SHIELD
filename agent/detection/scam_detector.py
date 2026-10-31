"""Single orchestration pipeline for all supported agent inputs."""

from __future__ import annotations

import base64
import binascii
import time
from typing import Any

from agent.config import Settings, get_settings
from agent.detection.recipient_analyzer import analyze_recipient
from agent.detection.risk_scorer import score_findings
from agent.detection.text_analyzer import analyze_text_message
from agent.detection.url_analyzer import analyze_url
from agent.gemma.model import GemmaClient, GemmaUnavailable
from agent.gemma.output_parser import ModelOutputError, parse_model_output
from agent.gemma.prompts import build_prompt
from agent.processing.ocr_processor import OCRUnavailable, extract_text_from_bytes
from agent.processing.text_processor import process_text
from agent.processing.qr_processor import (
    QRDecoderUnavailable,
    QRProcessingError,
    analyze_qr_image,
    parse_upi_payload,
)
from agent.schemas.analysis_schema import (
    AnalysisMetadata,
    AnalysisRequest,
    AnalysisResult,
    DetectionIndicator,
    InputType,
    RiskLevel,
    ScamCategory,
)


_CATEGORY_MAP = {
    "DANGEROUS_CREDENTIAL_REQUEST": ScamCategory.OTP_FRAUD,
    "KYC_OR_IMPERSONATION": ScamCategory.KYC_FRAUD,
    "IMPERSONATION": ScamCategory.IMPERSONATION,
    "PAYMENT_MANIPULATION": ScamCategory.PAYMENT_MANIPULATION,
    "REMOTE_ACCESS_SCAM": ScamCategory.REMOTE_ACCESS_SCAM,
    "SUSPICIOUS_URL": ScamCategory.SUSPICIOUS_URL,
    "URGENCY_OR_THREAT": ScamCategory.SOCIAL_ENGINEERING,
}


class ScamDetector:
    """Orchestrates deterministic detectors and optional Gemma analysis."""

    def __init__(
        self,
        *,
        gemma_client: GemmaClient | None = None,
        settings: Settings | None = None,
    ) -> None:
        self.settings = settings or get_settings()
        self.gemma_client = gemma_client or GemmaClient(self.settings)

    def analyze(self, request: AnalysisRequest | dict[str, Any]) -> AnalysisResult:
        """Analyze a validated request and return a validated result."""
        validated = (
            request
            if isinstance(request, AnalysisRequest)
            else AnalysisRequest.model_validate(request)
        )
        started = time.perf_counter()
        limitations: list[str] = []
        findings: list[dict[str, Any]] = []
        model_used = False
        model_analysis = None
        content = validated.content
        model_content = content
        context = validated.context

        try:
            is_image_content = self._looks_like_image(content)
            content_limit = (
                self.settings.max_image_size * 2 + 128
                if is_image_content
                else self.settings.max_input_length
            )
            if len(content) > content_limit:
                raise ValueError("Input exceeds the configured size limit")
            if validated.input_type == InputType.TEXT:
                process_text(content)
                findings = analyze_text_message(content)["findings"]
            elif validated.input_type == InputType.URL:
                findings = analyze_url(content)["findings"]
            elif validated.input_type == InputType.RECIPIENT:
                result = analyze_recipient(content, context.get("reputation"))
                findings = result["findings"]
                limitations.extend(result["limitations"])
            elif validated.input_type == InputType.QR:
                payload = (
                    analyze_qr_image(self._decode_image(content))
                    if self._looks_like_image(content)
                    else parse_upi_payload(content)
                )
                model_content = payload.payload
                if payload.unsupported_fields:
                    findings.append(
                        {
                            "rule_id": "qr.unsupported_fields",
                            "category": "SUSPICIOUS_QR",
                            "evidence": ", ".join(payload.unsupported_fields),
                            "severity": 1,
                            "explanation": "QR contains fields outside the supported UPI payload subset.",
                            "source": "deterministic",
                        }
                    )
                if payload.payee_upi_id:
                    recipient = analyze_recipient(
                        payload.payee_upi_id, context.get("reputation")
                    )
                    findings.extend(recipient["findings"])
                    limitations.extend(recipient["limitations"])
                limitations.extend(payload.limitations)
            elif validated.input_type == InputType.SCREENSHOT:
                ocr_result = extract_text_from_bytes(self._decode_image(content))
                model_content = ocr_result.text
                limitations.extend(ocr_result.limitations)
                process_text(ocr_result.text)
                findings = analyze_text_message(ocr_result.text)["findings"]
            else:
                raise ValueError(f"Unsupported input type: {validated.input_type}")
        except (ValueError, QRProcessingError) as exc:
            return self._failed_result(validated, str(exc), started)
        except (OCRUnavailable, QRDecoderUnavailable) as exc:
            limitations.append(str(exc))
            if validated.input_type in {InputType.SCREENSHOT, InputType.QR}:
                model_content = ""

        if self.settings.gemma_provider == "disabled":
            limitations.append("Gemma analysis is disabled; result uses deterministic checks only.")
        elif model_content.strip():
            try:
                response = self.gemma_client.generate(
                    build_prompt(
                        validated.input_type.value,
                        model_content[: self.settings.max_input_length],
                        deterministic_findings=findings,
                        context=self._safe_model_context(context),
                    )
                )
                model_analysis = parse_model_output(response)
                model_used = True
                findings.extend(self._supported_model_findings(model_analysis, model_content))
            except GemmaUnavailable as exc:
                limitations.append(f"Gemma analysis unavailable: {exc}")
            except ModelOutputError as exc:
                limitations.append(f"Gemma output rejected: {exc}")

        scoring = score_findings(findings, settings=self.settings)
        level = RiskLevel(scoring["level"])
        recommendation = self._recommendation(level, findings)
        scam_type = self._classify(findings)
        confidence = (
            model_analysis.confidence
            if model_used and model_analysis is not None
            else 0.65 if findings else 0.4
        )
        elapsed_ms = (time.perf_counter() - started) * 1000
        return AnalysisResult(
            analysis_id=validated.analysis_id,
            status="partial" if limitations else "completed",
            input_type=validated.input_type,
            is_suspicious=scoring["score"] > 0,
            risk_score=scoring["score"],
            risk_level=level,
            scam_type=scam_type,
            indicators=[DetectionIndicator.model_validate(item) for item in findings],
            explanation=scoring["explanation"],
            recommendation=recommendation,
            confidence=confidence,
            metadata=AnalysisMetadata(
                limitations=list(dict.fromkeys(limitations)),
                model_used=model_used,
                processing_ms=elapsed_ms,
            ),
        )

    def _decode_image(self, value: str) -> bytes:
        encoded = value
        if value.startswith("data:"):
            header, separator, encoded = value.partition(",")
            if not separator or ";base64" not in header.lower():
                raise ValueError("Image data URI must contain base64-encoded image data")
        elif value.startswith("base64:"):
            encoded = value[len("base64:") :]
        if len(encoded) > self.settings.max_image_size * 2:
            raise ValueError("Encoded image exceeds MAX_IMAGE_SIZE")
        try:
            image_bytes = base64.b64decode(encoded, validate=True)
        except (binascii.Error, ValueError) as exc:
            raise ValueError("Image content must be a valid base64 string or data URI") from exc
        if len(image_bytes) > self.settings.max_image_size:
            raise ValueError("Image exceeds MAX_IMAGE_SIZE")
        return image_bytes

    @staticmethod
    def _looks_like_image(value: str) -> bool:
        return value.startswith("base64:") or value.startswith("data:image/")

    @staticmethod
    def _safe_model_context(context: dict[str, Any]) -> dict[str, Any]:
        safe = {
            key: value
            for key, value in context.items()
            if key in {"reputation", "transaction_context", "sender_claim"}
        }
        return safe

    @staticmethod
    def _supported_model_findings(model_analysis: Any, content: str) -> list[dict[str, Any]]:
        supported: list[dict[str, Any]] = []
        normalized_content = content.casefold()
        category = model_analysis.scam_type.value
        for index, claim in enumerate(model_analysis.indicators):
            evidence = claim.strip()
            if len(evidence) < 3 or evidence.casefold() not in normalized_content:
                continue
            supported.append(
                {
                    "rule_id": f"gemma.supported.{index + 1}",
                    "category": category,
                    "evidence": evidence,
                    "severity": 1,
                    "explanation": "Gemma identified this exact phrase as a potential signal; treat it as unverified context.",
                    "source": "model",
                }
            )
        return supported

    @staticmethod
    def _classify(findings: list[dict[str, Any]]) -> ScamCategory:
        rule_ids = {str(item.get("rule_id", "")) for item in findings}
        specific_categories = (
            ("credential.upi_pin.request", ScamCategory.UPI_PIN_FRAUD),
            ("credential.otp.request", ScamCategory.OTP_FRAUD),
            ("remote_access.install", ScamCategory.REMOTE_ACCESS_SCAM),
            ("lottery.advance.fee", ScamCategory.LOTTERY_FRAUD),
            ("job.registration.fee", ScamCategory.JOB_FRAUD),
            ("kyc.urgent.update", ScamCategory.KYC_FRAUD),
        )
        for rule_id, category in specific_categories:
            if rule_id in rule_ids:
                return category
        priority = (
            "DANGEROUS_CREDENTIAL_REQUEST",
            "REMOTE_ACCESS_SCAM",
            "PAYMENT_MANIPULATION",
            "SUSPICIOUS_URL",
            "IMPERSONATION",
            "KYC_OR_IMPERSONATION",
            "URGENCY_OR_THREAT",
        )
        categories = {str(item.get("category", "")).upper() for item in findings}
        for category in priority:
            if category in categories:
                if category == "DANGEROUS_CREDENTIAL_REQUEST":
                    evidence = " ".join(
                        str(item.get("evidence", "")).lower() for item in findings
                        if item.get("category") == category
                    )
                    if "pin" in evidence:
                        return ScamCategory.UPI_PIN_FRAUD
                    if "password" in evidence or "passcode" in evidence:
                        return ScamCategory.UNKNOWN
                return _CATEGORY_MAP[category]
        for finding in findings:
            if finding.get("source") == "model":
                try:
                    return ScamCategory(str(finding.get("category", "UNKNOWN")))
                except ValueError:
                    break
        return ScamCategory.NORMAL if not findings else ScamCategory.UNKNOWN

    @staticmethod
    def _recommendation(level: RiskLevel, findings: list[dict[str, Any]]) -> str:
        categories = {str(item.get("category", "")).upper() for item in findings}
        if "DANGEROUS_CREDENTIAL_REQUEST" in categories:
            return "Do not share your OTP, UPI PIN, or password. Verify through your bank's official channel."
        if level == RiskLevel.HIGH:
            return "Pause. Do not pay, approve a collect request, or open the link; verify independently."
        if level == RiskLevel.MEDIUM:
            return "Pause and independently verify the sender, recipient, and payment details before acting."
        return "No strong warning signs were detected; this is not a guarantee of safety."

    @staticmethod
    def _failed_result(
        request: AnalysisRequest,
        message: str,
        started: float,
    ) -> AnalysisResult:
        return AnalysisResult(
            analysis_id=request.analysis_id,
            status="failed",
            input_type=request.input_type,
            is_suspicious=False,
            risk_score=0,
            risk_level=RiskLevel.LOW,
            scam_type=ScamCategory.UNKNOWN,
            indicators=[],
            explanation="Analysis could not be completed.",
            recommendation="Do not rely on this result; review the input and try again.",
            confidence=0.0,
            metadata=AnalysisMetadata(
                limitations=[message],
                processing_ms=(time.perf_counter() - started) * 1000,
            ),
        )
