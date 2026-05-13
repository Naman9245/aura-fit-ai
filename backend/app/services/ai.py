import base64
import json
from typing import Any

from app.core.config import settings

try:
    import google.generativeai as genai
except ImportError:  # pragma: no cover - optional runtime dependency
    genai = None


def _configure() -> bool:
    if not settings.gemini_api_key or genai is None:
        return False
    genai.configure(api_key=settings.gemini_api_key)
    return True


def generate_chat_reply(message: str, context: dict | None = None) -> str:
    if not _configure():
        return (
            "AURA AI is offline. Provide an API key to enable live responses."
        )

    model = genai.GenerativeModel("gemini-1.5-pro")
    prompt = (
        "You are AURA FIT AI, a futuristic fitness assistant. "
        "Use the user's context to answer clearly.\n\n"
        f"Context: {context or {}}\n"
        f"Message: {message}"
    )
    response = model.generate_content(prompt)
    return response.text or "I'm ready to help with your fitness plan."


def analyze_meal_image(image_bytes: bytes) -> dict[str, Any]:
    if not _configure():
        return {
            "items": [
                {"name": "Chicken Breast", "calories": 220, "protein": 43},
                {"name": "Rice", "calories": 300, "protein": 6},
            ],
            "totals": {
                "calories": 520,
                "protein": 49,
                "carbs": 62,
                "fats": 8,
            },
        }

    model = genai.GenerativeModel("gemini-1.5-pro")
    encoded = base64.b64encode(image_bytes).decode("utf-8")
    prompt = (
        "Analyze this meal image. Return JSON with items (name, calories, "
        "protein, carbs, fats) and totals."
    )
    response = model.generate_content(
        [
            prompt,
            {
                "mime_type": "image/jpeg",
                "data": encoded,
            },
        ]
    )
    if response.text:
        try:
            parsed = json.loads(response.text)
            if isinstance(parsed, dict):
                return parsed
        except json.JSONDecodeError:
            return {
                "items": [],
                "totals": {"calories": 0, "protein": 0, "carbs": 0, "fats": 0},
                "raw": response.text,
            }
    return {
        "items": [],
        "totals": {"calories": 0, "protein": 0, "carbs": 0, "fats": 0},
        "raw": "No response",
    }
