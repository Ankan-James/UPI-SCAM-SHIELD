"""Prompt helpers for the scam-detection agent."""

SYSTEM_PROMPT = """You are a UPI fraud risk classifier. Return a JSON object with keys: score, level, indicators, recommendation.
- score: integer 0-100
- level: low|medium|high
- indicators: string[]
- recommendation: short string
"""


def build_prompt(input_type: str, value: str) -> str:
    return (
        f"Analyze this {input_type} for scam risk.\n\n"
        f"Input:\n{value}\n\n"
        "Use cautious reasoning and return JSON only."
    )
