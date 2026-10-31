"""Ollama-backed Gemma client isolated from detection modules."""

from __future__ import annotations

import time
from typing import Any

import httpx

from agent.config import Settings, get_settings


class GemmaUnavailable(RuntimeError):
    """Raised when the configured model runtime cannot serve a request."""


class GemmaClient:
    """Small synchronous client for Ollama's generate and tags endpoints."""

    def __init__(
        self,
        settings: Settings | None = None,
        *,
        client: httpx.Client | None = None,
    ) -> None:
        self.settings = settings or get_settings()
        timeout = httpx.Timeout(
            self.settings.gemma_timeout,
            connect=min(self.settings.gemma_timeout, 5),
        )
        self._client = client or httpx.Client(timeout=timeout)
        self._owns_client = client is None

    def generate(self, prompt: str) -> str:
        """Submit a prompt and return the generated text."""
        if self.settings.gemma_provider == "disabled":
            raise GemmaUnavailable("Gemma analysis is disabled by configuration")
        if not prompt.strip():
            raise ValueError("prompt must not be empty")
        endpoint = f"{self.settings.gemma_base_url}/api/generate"
        payload: dict[str, Any] = {
            "model": self.settings.gemma_model,
            "prompt": prompt,
            "stream": False,
            "format": "json",
            "options": {"temperature": self.settings.gemma_temperature},
        }
        for attempt in range(self.settings.gemma_retries + 1):
            try:
                response = self._client.post(endpoint, json=payload)
                response.raise_for_status()
                try:
                    body = response.json()
                except ValueError as exc:
                    raise GemmaUnavailable("Ollama returned invalid JSON") from exc
                generated = body.get("response") if isinstance(body, dict) else None
                if (
                    not isinstance(generated, str)
                    or not generated.strip()
                    or len(generated) > 20_000
                ):
                    raise GemmaUnavailable("Ollama returned an empty or invalid response")
                return generated
            except (httpx.TimeoutException, httpx.ConnectError, httpx.RemoteProtocolError) as exc:
                if attempt >= self.settings.gemma_retries:
                    raise GemmaUnavailable(f"Could not reach Ollama: {exc}") from exc
            except httpx.HTTPStatusError as exc:
                status_code = exc.response.status_code
                if (
                    (status_code < 500 and status_code != 429)
                    or attempt >= self.settings.gemma_retries
                ):
                    raise GemmaUnavailable(
                        f"Ollama returned HTTP {status_code}"
                    ) from exc
            except httpx.HTTPError as exc:
                if attempt >= self.settings.gemma_retries:
                    raise GemmaUnavailable(f"Ollama request failed: {exc}") from exc
            if attempt < self.settings.gemma_retries:
                time.sleep(min(0.25 * (2**attempt), 2))
        raise GemmaUnavailable("Ollama request failed without a response")

    def health_check(self) -> dict[str, Any]:
        """Check runtime reachability and whether the configured model is installed."""
        if self.settings.gemma_provider == "disabled":
            return {"available": False, "reason": "Gemma analysis is disabled"}
        try:
            response = self._client.get(f"{self.settings.gemma_base_url}/api/tags")
            response.raise_for_status()
            body = response.json()
        except (httpx.HTTPError, ValueError) as exc:
            return {"available": False, "reason": f"Ollama health check failed: {exc}"}
        models = body.get("models", []) if isinstance(body, dict) else []
        names = {
            item.get("name")
            for item in models
            if isinstance(item, dict) and isinstance(item.get("name"), str)
        }
        available = self.settings.gemma_model in names
        return {
            "available": available,
            "model": self.settings.gemma_model,
            "reason": None if available else "Configured model is not installed in Ollama",
        }

    def close(self) -> None:
        """Release the underlying HTTP connection pool when owned by this client."""
        if self._owns_client:
            self._client.close()

    def __enter__(self) -> GemmaClient:
        return self

    def __exit__(self, *_: object) -> None:
        self.close()
