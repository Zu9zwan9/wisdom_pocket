from datetime import datetime
from fastapi import HTTPException, Request

from .redis_client import get_redis
from .config import settings


async def enforce_rate_limit(request: Request, key_prefix: str = "global", limit_per_minute: int | None = None):
    client_ip = request.client.host if request.client else "unknown"
    minute_bucket = datetime.utcnow().strftime("%Y%m%d%H%M")
    key = f"rl:{key_prefix}:{client_ip}:{minute_bucket}"
    redis = await get_redis()
    count = await redis.incr(key)
    if count == 1:
        await redis.expire(key, 65)
    limit = limit_per_minute or settings.RATE_LIMIT_PER_MINUTE
    if count > limit:
        raise HTTPException(status_code=429, detail="Rate limit exceeded")
