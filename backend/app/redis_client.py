import asyncio
import os
from typing import Optional
import redis.asyncio as redis

from .config import settings

_redis: Optional[redis.Redis] = None


async def get_redis() -> redis.Redis:
    global _redis
    if _redis is None:
        _redis = redis.from_url(settings.REDIS_URL, decode_responses=True)
    return _redis


async def close_redis():
    global _redis
    if _redis is not None:
        await _redis.close()
        _redis = None
