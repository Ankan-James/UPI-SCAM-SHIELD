"""Offline URL structure analysis; this module never opens URLs."""

from __future__ import annotations

import ipaddress
from typing import Any
from urllib.parse import parse_qsl, urlsplit

_SHORTENERS = {"bit.ly", "tinyurl.com", "t.co", "shorturl.at", "ow.ly", "is.gd"}
_SUSPICIOUS_LABELS = {"verify", "login", "secure", "kyc", "claim", "bonus", "update"}
_MULTI_LABEL_SUFFIXES = {"co.in", "com.in", "net.in", "org.in", "gov.in", "co.uk", "com.au"}
_FINANCIAL_BRANDS = {
    "axis",
    "amazon",
    "gpay",
    "googlepay",
    "hdfc",
    "icici",
    "npci",
    "paytm",
    "phonepe",
    "rbi",
    "sbi",
}


def _edit_distance_at_most_one(left: str, right: str) -> bool:
    """Return whether two labels differ by at most one insertion/deletion/substitution."""
    if abs(len(left) - len(right)) > 1:
        return False
    if left == right:
        return True
    if len(left) > len(right):
        left, right = right, left
    first = second = differences = 0
    while first < len(left) and second < len(right):
        if left[first] == right[second]:
            first += 1
            second += 1
            continue
        differences += 1
        if differences > 1:
            return False
        if len(left) == len(right):
            first += 1
        second += 1
    return differences + int(second < len(right)) <= 1


def analyze_url(value: str) -> dict[str, Any]:
    """Inspect URL syntax and visible indicators without network access."""
    raw = (value or "").strip()
    candidate = raw if "://" in raw else f"https://{raw}"
    findings: list[dict[str, Any]] = []

    def add(rule_id: str, category: str, severity: int, evidence: str, explanation: str) -> None:
        findings.append(
            {
                "rule_id": rule_id,
                "category": category,
                "severity": severity,
                "evidence": evidence[:300],
                "explanation": explanation,
                "source": "deterministic",
            }
        )

    try:
        parsed = urlsplit(candidate)
        hostname = (parsed.hostname or "").rstrip(".").lower()
        port = parsed.port
    except ValueError:
        parsed, hostname, port = None, "", None
    if parsed is None or parsed.scheme.lower() not in {"http", "https"} or not hostname:
        add("url.invalid", "SUSPICIOUS_URL", 3, raw or "(empty)", "URL is malformed or uses an unsupported scheme.")
    else:
        if parsed.username is not None or parsed.password is not None:
            add("url.userinfo", "SUSPICIOUS_URL", 4, parsed.netloc, "URL contains embedded user information that can obscure its destination.")
        if parsed.scheme.lower() == "http":
            add("url.cleartext_http", "SUSPICIOUS_URL", 2, parsed.scheme, "URL does not use HTTPS; HTTPS alone would not prove safety.")
        try:
            ipaddress.ip_address(hostname)
            add("url.ip_host", "SUSPICIOUS_URL", 4, hostname, "URL uses an IP address instead of a named host.")
        except ValueError:
            pass
        if hostname.startswith("xn--") or ".xn--" in hostname:
            add("url.punycode", "SUSPICIOUS_URL", 4, hostname, "Host contains an internationalized punycode label.")
        if any(hostname == domain or hostname.endswith(f".{domain}") for domain in _SHORTENERS):
            add("url.shortener", "SUSPICIOUS_URL", 3, hostname, "URL uses a link-shortening service that hides its destination.")
        if hostname.count(".") >= 4:
            add("url.deep_subdomains", "SUSPICIOUS_URL", 2, hostname, "Host has an unusually deep subdomain structure.")
        labels = set(hostname.split("."))
        ordered_labels = hostname.split(".")
        for label in ordered_labels:
            if any(
                len(brand) >= 4
                and label != brand
                and _edit_distance_at_most_one(label, brand)
                for brand in _FINANCIAL_BRANDS
            ):
                add(
                    "url.lookalike_brand",
                    "SUSPICIOUS_URL",
                    3,
                    label,
                    "Host label closely resembles a known financial-service brand; this is heuristic, not confirmation.",
                )
                break
        suffix_length = 2 if ".".join(ordered_labels[-2:]) in _MULTI_LABEL_SUFFIXES else 1
        registered_domain_index = max(0, len(ordered_labels) - suffix_length - 1)
        misplaced_brand = next(
            (
                label
                for index, label in enumerate(ordered_labels[:registered_domain_index])
                if label in _FINANCIAL_BRANDS
            ),
            None,
        )
        if misplaced_brand:
            add(
                "url.misleading_subdomain",
                "SUSPICIOUS_URL",
                3,
                misplaced_brand,
                "A financial-service brand appears in a subdomain rather than the apparent registered host.",
            )
        suspicious_labels = labels & _SUSPICIOUS_LABELS
        if suspicious_labels:
            add("url.sensitive_host_label", "SUSPICIOUS_URL", 2, ", ".join(sorted(suspicious_labels)),
                "Host uses a sign-in or account-action term; this is a weak signal and not proof of harm.")
        sensitive_path = {
            part.lower()
            for part in parsed.path.split("/")
            if part.lower() in _SUSPICIOUS_LABELS
        }
        if sensitive_path:
            add("url.sensitive_path", "SUSPICIOUS_URL", 2, ", ".join(sorted(sensitive_path)),
                "Path uses a sign-in or account-action term; this is a weak signal and not proof of harm.")
        try:
            query_keys = {key.lower() for key, _ in parse_qsl(parsed.query, max_num_fields=100)}
        except ValueError:
            query_keys = set()
            add("url.query.invalid", "SUSPICIOUS_URL", 2, "query", "URL query has too many fields to inspect safely.")
        if query_keys & {"redirect", "redirect_uri", "return_url", "continue", "next"}:
            add("url.redirect_parameter", "SUSPICIOUS_URL", 3, "redirect parameter",
                "URL contains a destination-redirection parameter.")
        if port not in (None, 80, 443):
            add("url.unusual_port", "SUSPICIOUS_URL", 2, str(port), "URL uses a non-standard web port.")

    score = min(100, sum(item["severity"] * 5 for item in {f["rule_id"]: f for f in findings}.values()))
    findings = list({item["rule_id"]: item for item in findings}.values())
    return {
        "score": score,
        "indicators": [item["evidence"] for item in findings],
        "risk_level": "HIGH" if score >= 70 else "MEDIUM" if score >= 30 else "LOW",
        "findings": findings,
        "hostname": hostname or None,
    }
