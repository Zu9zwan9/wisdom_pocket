from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel
from typing import Optional

from ..rate_limit import enforce_rate_limit
from ..redis_client import get_redis
from ..services import daily_quote as svc_daily_quote, random_quote as svc_random_quote
from ..security import get_current_user
from ..config import settings

router = APIRouter()


class QuoteOut(BaseModel):
    id: str
    text: str
    author: str
    category: str
    is_premium: bool


@router.get("/quotes/daily", response_model=QuoteOut)
async def get_daily_quote(request: Request, user_id: Optional[str] = Depends(get_current_user)):
    await enforce_rate_limit(request, key_prefix="daily")
    redis = await get_redis()
    cache_key = f"daily:{user_id or 'anon'}:{request.headers.get('x-date-key') or ''}"
    cached = await redis.get(cache_key)
    if cached:
        import json
        return QuoteOut(**json.loads(cached))
    q = svc_daily_quote(user_id)
    data = QuoteOut(**q.__dict__)
    await redis.set(cache_key, data.model_dump_json(), ex=settings.DAILY_CACHE_TTL)
    return data


@router.get("/quotes/random", response_model=QuoteOut)
async def get_random_quote(request: Request, premium: bool = False):
    await enforce_rate_limit(request, key_prefix="random")
    q = svc_random_quote(premium_ok=premium)
    return QuoteOut(**q.__dict__)
