import json
import random
from dataclasses import dataclass
from datetime import datetime
from functools import lru_cache
from typing import List, Optional

from .config import settings


@dataclass
class Quote:
    id: str
    text: str
    author: str
    category: str
    is_premium: bool


@lru_cache(maxsize=1)
def load_quotes() -> List[Quote]:
    with open(settings.QUOTES_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)
    quotes: List[Quote] = [
        Quote(
            id=str(item.get("id")),
            text=item.get("text", ""),
            author=item.get("author", "Unknown"),
            category=item.get("category", "general"),
            is_premium=bool(item.get("is_premium", False)),
        )
        for item in data
    ]
    return quotes


def daily_quote(user_id: Optional[str] = None) -> Quote:
    quotes = load_quotes()
    # Deterministic selection by date and user for basic personalization
    seed_str = datetime.utcnow().strftime("%Y-%m-%d") + (user_id or "")
    idx = abs(hash(seed_str)) % len(quotes)
    return quotes[idx]


def random_quote(premium_ok: bool = True) -> Quote:
    quotes = load_quotes()
    if not premium_ok:
        quotes = [q for q in quotes if not q.is_premium]
    return random.choice(quotes)
